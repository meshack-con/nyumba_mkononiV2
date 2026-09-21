"""Malipo ya ada ya kutangaza nyumba (TZS 5,000) kupitia Flutterwave.

Mtiririko: (1) mpangishaji/muuzaji anaita POST /payments/listing-fee/initiate
-> anapata `redirect_link` na kufunguliwa ukurasa wa Flutterwave kulipia;
(2) baada ya kulipa, frontend inaita GET /payments/listing-fee/{tx_ref}/status
kuthibitisha; (3) tukishathibitisha malipo, frontend inaita POST /properties
ikiwa imeambatanisha `payment_ref=tx_ref` - endpoint hiyo (kwenye main.py)
inakataa kuendelea kama malipo hayajathibitishwa kuwa yamefaulu (na
tx_ref hiyo haijatumika kwenye tangazo lingine kabla).

Flutterwave pia hutuma webhook (POST /payments/webhook) - hii ndiyo njia
ya uhakika zaidi ya kujua malipo yamefaulu (badala ya kutegemea tu
polling ya frontend, ambayo inaweza kukatika mtandao ukikatika)."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from . import flutterwave
from .auth import get_current_user
from .database import get_db, settings
from .models import Payment, PaymentPurpose, PaymentStatus, User
from .schemas import PaymentInitiateRequest, PaymentInitiateResponse, PaymentStatusResponse

router = APIRouter(prefix="/payments", tags=["payments"])


@router.post("/listing-fee/initiate", response_model=PaymentInitiateResponse, status_code=201)
async def initiate_listing_fee_payment(
    payload: PaymentInitiateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mpangishaji/muuzaji anaanzisha malipo ya TZS 5,000 kabla ya
    kutuma tangazo jipya la nyumba."""
    if current_user.role.value != "seller":
        raise HTTPException(status_code=403, detail="Hatua hii ni ya seller pekee")

    tx_ref = f"NM-{uuid.uuid4().hex[:20]}"
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

    # redirect_url: Flutterwave itamrudisha seller hapa baada ya kulipa
    # (au kughairi) - ukurasa huu si lazima uwe na maana kwenye app ya
    # simu, ni kimsingi tu "mwisho wa safari" wa malipo kwenye browser.
    redirect_url = f"{list(settings.cors_origins.split(','))[0].strip()}/malipo-yamekamilika" if settings.cors_origins else "https://nyumbamkononi.co.tz/malipo-yamekamilika"

    try:
        result = await flutterwave.create_listing_fee_charge(
            tx_ref=tx_ref,
            phone_number=payload.phone_number,
            full_name=current_user.jina_kamili,
            email=current_user.email or "",
            redirect_url=redirect_url,
        )
    except flutterwave.FlutterwaveError as error:
        payment.status = PaymentStatus.FAILED
        db.commit()
        raise HTTPException(status_code=502, detail=f"Imeshindikana kuanzisha malipo: {error}") from None

    payment.charge_id = result["charge_id"]
    if result.get("raw_status"):
        payment.status = PaymentStatus(flutterwave._normalize_status(str(result["raw_status"]).lower()))
    db.commit()
    db.refresh(payment)

    return PaymentInitiateResponse(
        tx_ref=payment.tx_ref,
        amount=payment.amount,
        currency=payment.currency,
        redirect_link=result.get("redirect_link"),
        status=payment.status.value,
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
    """Frontend inaita hii mara kwa mara (polling) baada ya seller
    kurudi kutoka kwenye ukurasa wa Flutterwave, kuangalia kama malipo
    yamekamilika."""
    payment = _get_own_payment(tx_ref, current_user, db)

    if payment.status == PaymentStatus.PENDING and payment.charge_id:
        try:
            live_status = await flutterwave.get_charge_status(payment.charge_id)
        except flutterwave.FlutterwaveError:
            live_status = "pending"
        if live_status == "successful":
            payment.status = PaymentStatus.SUCCESSFUL
            db.commit()
        elif live_status == "failed":
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
async def flutterwave_webhook(request: Request, db: Session = Depends(get_db)):
    """Flutterwave inatuma hapa moja kwa moja pindi malipo yanapokamilika
    (au kushindwa) - hii ndiyo njia ya uhakika zaidi (badala ya kutegemea
    polling pekee). Weka URL hii (https://DOMENI-YAKO/payments/webhook)
    kwenye Flutterwave Dashboard -> Settings -> Webhooks, na weka "Secret
    Hash" ile ile uliyoiweka kwenye FLUTTERWAVE_WEBHOOK_SECRET_HASH."""
    raw_body = await request.body()
    signature = request.headers.get("flutterwave-signature") or request.headers.get("verif-hash")
    if not flutterwave.verify_webhook_signature(raw_body, signature):
        raise HTTPException(status_code=401, detail="Saini ya webhook si sahihi")

    payload = await request.json()
    tx_ref = flutterwave._find_first(payload, ("reference", "tx_ref"))
    if not tx_ref:
        return {"status": "ignored"}

    payment = db.scalar(select(Payment).where(Payment.tx_ref == str(tx_ref)))
    if payment is None or payment.status != PaymentStatus.PENDING:
        return {"status": "ignored"}

    # Kwa usalama, hatutegemei tu maudhui ya webhook - tunauliza
    # Flutterwave moja kwa moja hali halisi ya charge kabla ya kuithibitisha.
    if payment.charge_id:
        try:
            live_status = await flutterwave.get_charge_status(payment.charge_id)
        except flutterwave.FlutterwaveError:
            return {"status": "retry-later"}
        if live_status == "successful":
            payment.status = PaymentStatus.SUCCESSFUL
        elif live_status == "failed":
            payment.status = PaymentStatus.FAILED
        db.commit()

    return {"status": "ok"}
