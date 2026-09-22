"""Mteja wa ClickPesa API - hutumika kutoza ada ya kutangaza nyumba
(TZS 5,000) kwa mpangishaji/muuzaji kabla tangazo halijapokelewa, kwa
kutumia USSD-PUSH (M-Pesa, Tigo Pesa, Airtel Money, Halopesa).

MTIRIRIKO WA MALIPO (tofauti muhimu na Flutterwave iliyokuwepo kabla):
ClickPesa HAITOI "redirect_link" ya kufungua browser - badala yake,
`initiate_ussd_push` inatuma ombi la USSD moja kwa moja kwenye simu ya
muuzaji (channel: M-PESA / TIGO-PESA / AIRTEL-MONEY / HALOPESA), na
muuzaji anaithibitisha kwa kuweka PIN yake ya simu. Kwa hiyo frontend
(Flutter) haihitaji tena kufungua browser (`url_launcher`) - inahitaji
tu kumwambia mtumiaji "angalia simu yako" kisha ku-poll status, au
kusubiri webhook.

Rejea rasmi: https://docs.clickpesa.com (Generate Token, USSD-PUSH,
Query Payment Status, Webhooks, Checksum).

MUHIMU: ClickPesa haina mazingira tofauti ya "sandbox" - majaribio
hufanyika dhidi ya production halisi kwa kiasi kidogo cha pesa (soma
https://docs.clickpesa.com/home/sandbox-and-testing-environment).
"""
from __future__ import annotations

import hashlib
import hmac
import json
import time
import uuid

import httpx

from .database import settings


class ClickPesaError(Exception):
    """Hitilafu yoyote inayotokana na mawasiliano na ClickPesa."""


_token_cache: dict[str, object] = {"access_token": None, "expires_at": 0.0}


# --------------------------------------------------------------------
# Checksum (HMAC-SHA256 juu ya payload iliyopangwa kialfabeti) - kama
# ilivyoainishwa kwenye https://docs.clickpesa.com/home/checksum. Hii
# hutumika PANDE ZOTE MBILI: (1) kuongeza `checksum` kwenye ombi
# tunalotuma ClickPesa (kama umewasha "checksum" kwenye Dashboard yako),
# na (2) kuthibitisha kuwa webhook inayotujia kweli imetoka ClickPesa.
# --------------------------------------------------------------------

def _canonicalize(value):
    if isinstance(value, dict):
        return {key: _canonicalize(value[key]) for key in sorted(value.keys())}
    if isinstance(value, list):
        return [_canonicalize(item) for item in value]
    return value


def compute_checksum(checksum_key: str, payload: dict) -> str:
    canonical = _canonicalize(payload)
    payload_string = json.dumps(canonical, separators=(",", ":"))
    return hmac.new(checksum_key.encode("utf-8"), payload_string.encode("utf-8"), hashlib.sha256).hexdigest()


def verify_checksum(checksum_key: str, payload: dict, received_checksum: str | None) -> bool:
    if not checksum_key or not received_checksum:
        return False
    payload_for_check = {k: v for k, v in payload.items() if k not in ("checksum", "checksumMethod")}
    expected = compute_checksum(checksum_key, payload_for_check)
    return hmac.compare_digest(expected, received_checksum)


def _with_checksum(payload: dict) -> dict:
    """Inaongeza `checksum` kwenye payload TU kama umeweka
    CLICKPESA_CHECKSUM_KEY (yaani umewasha 'Checksum' kwenye ClickPesa
    Dashboard -> Settings -> Developers, kwenye application yako)."""
    if not settings.clickpesa_checksum_key:
        return payload
    return {**payload, "checksum": compute_checksum(settings.clickpesa_checksum_key, payload)}


# --------------------------------------------------------------------
# Namba za simu za Tanzania - ClickPesa inataka mfumo "255712345678"
# (msimbo wa nchi, bila alama ya +). Mtumiaji mara nyingi anaandika
# "07XXXXXXXX" - hii inaigeuza kuwa muundo sahihi.
# --------------------------------------------------------------------

def normalize_tz_phone(raw_phone: str) -> str:
    digits = "".join(ch for ch in raw_phone if ch.isdigit())
    if digits.startswith("255") and len(digits) == 12:
        return digits
    if digits.startswith("0") and len(digits) == 10:
        return "255" + digits[1:]
    if len(digits) == 9:
        return "255" + digits
    # Haikuwezekana kutambua muundo - turudishe kama ilivyo na tuache
    # ClickPesa yenyewe ikatae kama si sahihi (itarudisha 400 wazi).
    return digits


# --------------------------------------------------------------------
# Authorization token (JWT, halali kwa saa 1) - tunaipata kwa
# client-id/api-key kwenye HEADERS (siyo body), tofauti na OAuth2 ya
# kawaida.
# --------------------------------------------------------------------

async def _get_access_token() -> str:
    now = time.time()
    cached_token = _token_cache.get("access_token")
    if cached_token and now < float(_token_cache["expires_at"]):
        return str(cached_token)

    if not settings.clickpesa_client_id or not settings.clickpesa_api_key:
        raise ClickPesaError(
            "CLICKPESA_CLIENT_ID / CLICKPESA_API_KEY hazijawekwa kwenye backend/.env"
        )

    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.post(
            f"{settings.clickpesa_base_url}/generate-token",
            headers={
                "client-id": settings.clickpesa_client_id,
                "api-key": settings.clickpesa_api_key,
            },
        )
    if response.status_code >= 400:
        raise ClickPesaError(f"Imeshindikana kupata ClickPesa token: {response.text[:300]}")
    data = response.json()
    token = data.get("token")  # tayari ina neno "Bearer " mbele yake
    if not token:
        raise ClickPesaError("ClickPesa haikurudisha token")
    # JWT ni halali kwa saa 1 - tunaiweka akiba kwa dakika 55 kuepuka
    # kutumia token iliyokwisha muda kabla ya kuomba mpya.
    _token_cache["access_token"] = token
    _token_cache["expires_at"] = now + 55 * 60
    return str(token)


async def _auth_headers() -> dict:
    token = await _get_access_token()
    return {"Authorization": token, "Content-Type": "application/json"}


# --------------------------------------------------------------------
# USSD-PUSH: preview (hiari - inathibitisha namba/mtandao kabla ya
# kutoza) na initiate (kutuma ombi halisi kwenye simu ya mteja).
# --------------------------------------------------------------------

async def preview_ussd_push(*, order_reference: str, amount: int, phone_number: str) -> dict:
    payload = _with_checksum({
        "amount": str(amount),
        "currency": settings.property_listing_currency,
        "orderReference": order_reference,
        "phoneNumber": phone_number,
        "fetchSenderDetails": True,
    })
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.post(
            f"{settings.clickpesa_base_url}/payments/preview-ussd-push-request",
            headers=await _auth_headers(),
            json=payload,
        )
    data = _safe_json(response)
    if response.status_code >= 400:
        raise ClickPesaError(str(data.get("message") or "Haikuwezekana kuangalia mtandao wa malipo"))
    return data


async def initiate_ussd_push(*, order_reference: str, amount: int, phone_number: str) -> dict:
    """Inatuma ombi la USSD-PUSH kwenye simu ya muuzaji ili alipe ada ya
    kutangaza nyumba. Muuzaji atapokea ujumbe/USSD kwenye simu yake na
    kuthibitisha kwa PIN yake - hatua hiyo ya mwisho HAIFANYIKI humu
    kwenye backend wala kwenye app - inafanyika NJE, kwenye mtandao wa
    simu wa muuzaji mwenyewe (M-Pesa/Tigo Pesa/Airtel Money/Halopesa).

    Inarudisha dict yenye `id` (ClickPesa transaction id), `status`
    (PROCESSING/SUCCESS/FAILED/SETTLED) na `channel`."""
    payload = _with_checksum({
        "amount": str(amount),
        "currency": settings.property_listing_currency,
        "orderReference": order_reference,
        "phoneNumber": phone_number,
    })
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(
            f"{settings.clickpesa_base_url}/payments/initiate-ussd-push-request",
            headers=await _auth_headers(),
            json=payload,
        )
    data = _safe_json(response)
    if response.status_code >= 400:
        raise ClickPesaError(str(data.get("message") or "Malipo hayakuweza kuanzishwa"))

    transaction_id = data.get("id")
    if not transaction_id:
        raise ClickPesaError(f"ClickPesa haikurudisha transaction id: {str(data)[:300]}")

    return {
        "transaction_id": str(transaction_id),
        "status": normalize_status(str(data.get("status", ""))),
        "channel": data.get("channel"),
        "raw": data,
    }


async def get_payment_status(order_reference: str) -> dict | None:
    """Inauliza ClickPesa hali ya malipo kwa kutumia order reference
    (tx_ref). ClickPesa hurudisha ORODHA (list) ya majaribio yaliyofanyika
    kwa reference hiyo - tunachukua la mwisho (jipya zaidi)."""
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.get(
            f"{settings.clickpesa_base_url}/payments/{order_reference}",
            headers=await _auth_headers(),
        )
    if response.status_code == 404:
        return None
    try:
        data = response.json()
    except ValueError:
        data = None
    if response.status_code >= 400:
        message = data.get("message") if isinstance(data, dict) else "Imeshindikana kuangalia hali ya malipo"
        raise ClickPesaError(str(message))
    if not isinstance(data, list) or not data:
        return None
    latest = sorted(data, key=lambda item: item.get("updatedAt", ""))[-1]
    return {
        "transaction_id": latest.get("id"),
        "status": normalize_status(str(latest.get("status", ""))),
        "channel": latest.get("channel"),
        "collected_amount": latest.get("collectedAmount"),
        "raw": latest,
    }


def normalize_status(raw_status: str) -> str:
    upper = raw_status.upper()
    if upper in {"SUCCESS", "SETTLED"}:
        return "successful"
    if upper == "FAILED":
        return "failed"
    return "pending"  # PROCESSING, PENDING, au chochote kingine


def _safe_json(response: httpx.Response) -> dict:
    try:
        data = response.json()
    except ValueError:
        return {}
    return data if isinstance(data, dict) else {"_list": data}
