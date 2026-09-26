"""Malipo ya ada ya kutangaza nyumba (TZS 5,000) kupitia ClickPesa
(USSD-PUSH - M-Pesa, Tigo Pesa, Airtel Money, Halopesa).

Mtiririko: (1) mpangishaji/muuzaji anaita POST
/payments/listing-fee/initiate akiwa ameweka namba yake ya simu ->
ClickPesa inatuma ombi la USSD moja kwa moja kwenye simu yake (HAKUNA
"redirect_link" ya browser - tofauti na Flutterwave iliyokuwepo kabla);
(2) MUUZAJI MWENYEWE, KWENYE SIMU YAKE, ndiye anayekamilisha hatua ya
mwisho - anaona ombi la USSD/push notification kutoka kwa mtandao wake
(M-Pesa/Tigo Pesa/Airtel Money/Halopesa) na kuweka PIN yake ya simu
kuidhinisha malipo. Hatua hiyo HAIFANYIKI ndani ya app wala backend -
inafanyika nje, kwenye mfumo wa mtandao wa simu wa muuzaji;
(3) frontend inaita GET /payments/listing-fee/{tx_ref}/status
kuthibitisha (polling), na/au (4) ClickPesa inatuma webhook (POST
/payments/webhook) mara malipo yanapokamilika/kushindwa - hii ndiyo
njia ya uhakika zaidi; (5) tukishathibitisha malipo, frontend inaita
POST /properties ikiwa imeambatanisha `payment_ref=tx_ref`."""
from __future__ import annotations

import uuid

import httpx
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from . import clickpesa
from .auth import get_current_user
from .database import get_db, settings
from .models import Payment, PaymentPurpose, PaymentStatus, User
from .schemas import PaymentInitiateRequest, PaymentInitiateResponse, PaymentStatusResponse

router = APIRouter(prefix="/payments", tags=["payments"])


def _new_tx_ref() -> str:
    # ClickPesa: orderReference lazima iwe herufi/namba TU (alphanumeric),
    # na isizidi herufi 20 (kikomo cha watoa huduma za mitandao ya simu).
    return f"NM{uuid.uuid4().hex[:18]}"


@router.post("/listing-fee/initiate", response_model=PaymentInitiateResponse, status_code=201)
async def initiate_listing_fee_payment(
    payload: PaymentInitiateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mpangishaji/muuzaji anaanzisha malipo ya TZS 5,000 kabla ya
    kutuma tangazo jipya la nyumba. Ombi la USSD litatumwa moja kwa
    moja kwenye simu yake."""
    if current_user.role.value != "seller":
        raise HTTPException(status_code=403, detail="Hatua hii ni ya seller pekee")

    phone_number = clickpesa.normalize_tz_phone(payload.phone_number)
    tx_ref = _new_tx_ref()
    payment = Payment(
        user_id=current_user.id,
        tx_ref=tx_ref,
        purpose=PaymentPurpose.PROPERTY_LISTING,
        amount=settings.property_listing_fee,
        currency=settings.property_listing_currency,
        status=PaymentStatus.PENDING,
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)

    try:
        result = await clickpesa.initiate_ussd_push(
            order_reference=tx_ref,
            amount=settings.property_listing_fee,
            phone_number=phone_number,
        )
    except clickpesa.ClickPesaError as error:
        # ClickPesa YENYEWE imekataa ombi wazi (mfano: namba batili,
        # channel haipatikani, n.k.) - hii ni kushindwa kwa uhakika kabla
        # ya USSD kutumwa kwenye simu, hivyo ni salama kuweka FAILED.
        payment.status = PaymentStatus.FAILED
        db.commit()
        raise HTTPException(status_code=502, detail=f"Imeshindikana kuanzisha malipo: {error}") from None
    except (httpx.TimeoutException, httpx.ConnectError, httpx.HTTPError) as error:
        # Ombi la HTTP kwenda ClickPesa limekwama/limechelewa (mfano:
        # muuzaji amechukua muda kuweka PIN yake) - HATUJUI kama malipo
        # yamefanikiwa au la upande wa mtandao wa simu. TUSIWEKE FAILED
        # papo hapo: tunaacha PENDING na kumrudishia mtumiaji tx_ref ile
        # ile, ili frontend ianze ku-poll/kusubiri webhook ithibitishe
        # ukweli halisi badala ya kuzima malipo ambayo huenda tayari
        # yamekamilika kwenye simu ya muuzaji.
        db.commit()
        return PaymentInitiateResponse(
            tx_ref=payment.tx_ref,
            amount=payment.amount,
            currency=payment.currency,
            status=payment.status.value,
            channel=None,
        )
    except Exception as error:
        # Hitilafu nyingine isiyotarajiwa - bila hii, exception hii
        # inatoroka bila kushikwa na inasababisha 500 isiyo na CORS
        # headers (browser inaonyesha "blocked by CORS").
        payment.status = PaymentStatus.FAILED
        db.commit()
        raise HTTPException(status_code=502, detail=f"Imeshindikana kuwasiliana na ClickPesa: {error}") from None

    payment.charge_id = result["transaction_id"]
    if result["status"] == "successful":
        payment.status = PaymentStatus.SUCCESSFUL
    elif result["status"] == "failed":
        payment.status = PaymentStatus.FAILED
    db.commit()
    db.refresh(payment)

    return PaymentInitiateResponse(
        tx_ref=payment.tx_ref,
        amount=payment.amount,
        currency=payment.currency,
        status=payment.status.value,
        channel=result.get("channel"),
    )


def _get_own_payment(tx_ref: str, current_user: User, db: Session) -> Payment:
    payment = db.scalar(select(Payment).where(Payment.tx_ref == tx_ref))
    if payment is None or payment.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Malipo hayakupatikana")
    return payment


@router.get("/listing-fee/{tx_ref}/status", response_model=PaymentStatusResponse)
async def get_listing_fee_payment_status(
    tx_ref: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Frontend inaita hii mara kwa mara (polling) baada ya muuzaji
    kuombwa kuweka PIN kwenye simu yake, kuangalia kama malipo
    yamekamilika."""
    payment = _get_own_payment(tx_ref, current_user, db)

    if payment.status == PaymentStatus.PENDING:
        try:
            live = await clickpesa.get_payment_status(payment.tx_ref)
        except clickpesa.ClickPesaError:
            live = None
        if live is not None:
            if live["status"] == "successful":
                payment.status = PaymentStatus.SUCCESSFUL
                db.commit()
            elif live["status"] == "failed":
                payment.status = PaymentStatus.FAILED
                db.commit()

    return PaymentStatusResponse(
        tx_ref=payment.tx_ref,
        status=payment.status.value,
        amount=payment.amount,
        currency=payment.currency,
        used=payment.property_id is not None,
    )


@router.post("/webhook", status_code=200)
async def clickpesa_webhook(request: Request, db: Session = Depends(get_db)):
    """ClickPesa inatuma hapa moja kwa moja pindi malipo yanapokamilika
    (PAYMENT RECEIVED) au kushindwa (PAYMENT FAILED) - hii ndiyo njia ya
    uhakika zaidi (badala ya kutegemea tu polling ya frontend, ambayo
    inaweza kukatika mtandao ukikatika). Weka URL hii
    (https://DOMENI-YAKO/payments/webhook) kwenye ClickPesa Merchant
    Dashboard -> Settings -> Developers -> (chagua application yako) ->
    Application Webhooks, kwa matukio 'PAYMENT RECEIVED' na
    'PAYMENT FAILED'."""
    payload = await request.json()

    # Kama umewasha "Checksum" kwenye ClickPesa Dashboard kwa
    # application yako, kila webhook itakuja na `checksum`/`checksumMethod`
    # - tunaithibitisha hapa kabla ya kuamini chochote kwenye payload.
    if settings.clickpesa_checksum_key:
        received_checksum = payload.get("checksum")
        if not clickpesa.verify_checksum(settings.clickpesa_checksum_key, payload, received_checksum):
            raise HTTPException(status_code=401, detail="Checksum ya webhook si sahihi")

    data = payload.get("data") or {}
    tx_ref = data.get("orderReference")
    if not tx_ref:
        return {"status": "ignored"}

    payment = db.scalar(select(Payment).where(Payment.tx_ref == str(tx_ref)))
    if payment is None or payment.status != PaymentStatus.PENDING:
        return {"status": "ignored"}

    # Kwa usalama, hatutegemei tu maudhui ya webhook - tunauliza
    # ClickPesa moja kwa moja hali halisi ya malipo kabla ya kuithibitisha.
    try:
        live = await clickpesa.get_payment_status(payment.tx_ref)
    except clickpesa.ClickPesaError:
        return {"status": "retry-later"}
    if live is not None:
        if live["status"] == "successful":
            payment.status = PaymentStatus.SUCCESSFUL
            if live.get("transaction_id"):
                payment.charge_id = str(live["transaction_id"])
        elif live["status"] == "failed":
            payment.status = PaymentStatus.FAILED
        db.commit()

    return {"status": "ok"}
