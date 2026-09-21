"""Mteja wa Flutterwave v4 API (OAuth2 client-credentials) - hutumika
kutoza ada ya kutangaza nyumba (TZS 5,000) kwa mpangishaji/muuzaji kabla
tangazo halijapokelewa.

MUHIMU KUSOMA: hii ni API mpya ya Flutterwave (v4) inayotumia "Client ID"
na "Client Secret" (OAuth2) - siyo ile ya zamani ya v3 (Public Key /
Secret Key ya "FLWSECK-..."). Credentials zilizowekwa kwenye backend/.env
ni za "Test API keys" (sandbox) kutoka Flutterwave Dashboard.

Muundo kamili wa "payment_method" kwa mitandao ya simu ya Tanzania
(M-Pesa, Tigo Pesa, Airtel Money, Halopesa) unaweza kubadilika kidogo
kwenye v4 kadri Flutterwave wanavyoendelea kuiboresha API hii. Kwenye
mazingira haya sina uwezo wa kufanya "live call" kwenda Flutterwave
(hakuna network access hapa) kwa hiyo sijaweza kujaribu response halisi.
Kama ukipata error ya "validation" wakati wa majaribio yako ya sandbox,
angalia https://developer.flutterwave.com/docs/mobile-money kwa muundo
mpya kabisa na urekebishe `_build_charge_payload` hapa chini - ndipo
sehemu pekee inayohitaji kubadilishwa.
"""
from __future__ import annotations

import base64
import hashlib
import hmac
import time
import uuid

import httpx

from .database import settings


class FlutterwaveError(Exception):
    """Hitilafu yoyote inayotokana na mawasiliano na Flutterwave."""


_token_cache: dict[str, object] = {"access_token": None, "expires_at": 0.0}


async def _get_access_token() -> str:
    """Inapata (na kuweka akiba/cache) OAuth2 access token kwa dakika
    kadhaa, kwa kutumia Client ID/Secret - kuepuka kuomba token mpya kwa
    kila ombi (Flutterwave wanaweka rate-limit kwenye hilo)."""
    now = time.time()
    cached_token = _token_cache.get("access_token")
    if cached_token and now < float(_token_cache["expires_at"]):
        return str(cached_token)

    if not settings.flutterwave_client_id or not settings.flutterwave_client_secret:
        raise FlutterwaveError(
            "FLUTTERWAVE_CLIENT_ID / FLUTTERWAVE_CLIENT_SECRET hazijawekwa kwenye backend/.env"
        )

    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.post(
            settings.flutterwave_idp_url,
            data={
                "client_id": settings.flutterwave_client_id,
                "client_secret": settings.flutterwave_client_secret,
                "grant_type": "client_credentials",
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
    if response.status_code >= 400:
        raise FlutterwaveError(f"Imeshindikana kupata Flutterwave access token: {response.text[:300]}")
    data = response.json()
    token = data.get("access_token")
    if not token:
        raise FlutterwaveError("Flutterwave haikurudisha access_token")
    ttl_seconds = int(data.get("expires_in", 600))
    _token_cache["access_token"] = token
    _token_cache["expires_at"] = now + max(ttl_seconds - 30, 30)
    return str(token)


def _split_name(full_name: str) -> tuple[str, str]:
    parts = full_name.strip().split(" ", 1)
    first = parts[0] if parts and parts[0] else "Mteja"
    last = parts[1] if len(parts) > 1 and parts[1] else first
    return first, last


def _build_charge_payload(
    *, tx_ref: str, amount: int, currency: str, phone_number: str, full_name: str, email: str, redirect_url: str
) -> dict:
    first, last = _split_name(full_name)
    return {
        "amount": amount,
        "currency": currency,
        "reference": tx_ref,
        "redirect_url": redirect_url,
        # "mobile_money" na "country": "TZ" humwachia Flutterwave
        # amwombe mteja mtandao (network) na namba kwenye ukurasa wao wa
        # malipo (hosted page) - hii ndiyo njia salama zaidi isiyohitaji
        # sisi kujua muundo kamili wa kila mtandao wa Tanzania.
        "payment_method": {
            "type": "mobile_money",
            "country": "TZ",
        },
        "customer": {
            "email": email or "mteja@nyumbamkononi.co.tz",
            "phone": {"country_code": "255", "number": phone_number},
            "name": {"first": first, "last": last},
        },
    }


def _find_first(data: dict, keys: tuple[str, ...]):
    """Inatafuta key ya kwanza inayopatikana ndani ya dict, ikichimba
    ndani ya 'data' na 'next_action' pia - Flutterwave hurudisha muundo
    tofauti kidogo kutegemea njia ya malipo."""
    stack = [data]
    seen = set()
    while stack:
        current = stack.pop()
        if not isinstance(current, dict) or id(current) in seen:
            continue
        seen.add(id(current))
        for key in keys:
            if key in current and current[key]:
                return current[key]
        stack.extend(value for value in current.values() if isinstance(value, dict))
    return None


async def create_listing_fee_charge(
    *, tx_ref: str, phone_number: str, full_name: str, email: str, redirect_url: str
) -> dict:
    """Inaanzisha malipo ya ada ya kutangaza nyumba kwenye Flutterwave.

    Inarudisha dict yenye `charge_id` na `redirect_link` (ukurasa wa
    Flutterwave ambao seller atafunguliwa kumalizia malipo)."""
    token = await _get_access_token()
    payload = _build_charge_payload(
        tx_ref=tx_ref,
        amount=settings.property_listing_fee,
        currency=settings.property_listing_currency,
        phone_number=phone_number,
        full_name=full_name,
        email=email,
        redirect_url=redirect_url,
    )
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(
            f"{settings.flutterwave_base_url}/orchestration/direct-charges",
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
                "X-Trace-Id": uuid.uuid4().hex,
                "X-Idempotency-Key": tx_ref,
            },
            json=payload,
        )
    try:
        data = response.json()
    except ValueError:
        data = {}
    if response.status_code >= 400:
        message = data.get("message") or _find_first(data, ("message",)) or "Malipo hayakuweza kuanzishwa"
        raise FlutterwaveError(str(message))

    charge_id = _find_first(data, ("id", "charge_id"))
    redirect_link = _find_first(data, ("redirect", "link", "url", "checkout_url", "authorization_url"))
    if isinstance(redirect_link, dict):
        redirect_link = redirect_link.get("url") or redirect_link.get("link")
    status_value = _find_first(data, ("status",))

    if not charge_id:
        raise FlutterwaveError(f"Flutterwave haikurudisha charge id: {str(data)[:300]}")

    return {"charge_id": str(charge_id), "redirect_link": redirect_link, "raw_status": status_value, "raw": data}


async def get_charge_status(charge_id: str) -> str:
    """Inauliza Flutterwave hali ya charge fulani. Inarudisha moja ya
    'successful', 'failed', au 'pending'."""
    token = await _get_access_token()
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.get(
            f"{settings.flutterwave_base_url}/charges/{charge_id}",
            headers={"Authorization": f"Bearer {token}"},
        )
    if response.status_code >= 400:
        raise FlutterwaveError(f"Imeshindikana kuangalia hali ya malipo: {response.text[:300]}")
    data = response.json()
    raw_status = str(_find_first(data, ("status",)) or "").lower()
    return _normalize_status(raw_status)


def _normalize_status(raw_status: str) -> str:
    if raw_status in {"successful", "success", "completed", "complete"}:
        return "successful"
    if raw_status in {"failed", "error", "cancelled", "canceled", "declined"}:
        return "failed"
    return "pending"


def verify_webhook_signature(raw_body: bytes, signature_header: str | None) -> bool:
    """Inathibitisha kuwa webhook kweli imetoka kwa Flutterwave, kwa
    kulinganisha HMAC-SHA256 ya mwili wa ombi (raw body) na
    FLUTTERWAVE_WEBHOOK_SECRET_HASH iliyowekwa kwenye Dashboard yako ya
    Flutterwave (Settings -> Webhooks)."""
    if not signature_header or not settings.flutterwave_webhook_secret_hash:
        return False
    expected = base64.b64encode(
        hmac.new(
            settings.flutterwave_webhook_secret_hash.encode("utf-8"),
            raw_body,
            hashlib.sha256,
        ).digest()
    ).decode("utf-8")
    return hmac.compare_digest(expected, signature_header)
