"""Msaidizi wa AI wa Nyumba Mkononi - proxy kwenda Groq.

Flutter (frontend) HAIWASILIANI na Groq moja kwa moja tena - inaita
endpoint hii (`POST /ai/chat`), na SISI (backend) ndio tunaowasiliana na
Groq kwa kutumia GROQ_API_KEY iliyowekwa kwenye env vars za Render.
Hii inahakikisha key haiwahi kuonekana kwenye JS bundle ya web wala
kwenye browser ya mtumiaji - tofauti na kuiweka moja kwa moja kwenye
Flutter (--dart-define), ambayo inaonekana kirahisi kwenye DevTools.
"""
from __future__ import annotations

import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from .database import settings

router = APIRouter(prefix="/ai", tags=["ai"])

_GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
_GROQ_MODEL = "openai/gpt-oss-120b"

_SYSTEM_PROMPT = """
Wewe ni "Msaidizi wa Nyumba Mkononi" - msaidizi wa huduma kwa wateja wa app ya Nyumba Mkononi PEKEE.

Nyumba Mkononi ni jukwaa la Tanzania la kutafuta na kuweka matangazo ya nyumba, vyumba, na viwanja kwa ajili ya kukodisha (kupanga) au kununua/kuuza. Huduma zinazopatikana kwenye jukwaa hili ni:
- Kutafuta nyumba kwa eneo, bei (kuanzia/hadi kwa TZS), aina (Chumba/Nyumba/Kiwanja/Zote), na hali (Kwa kupanga / Kwa kununua)
- Vichujio vya ziada: Wi-Fi, sehemu ya kuegesha gari, choo cha ndani, umeme, maji ndani ya nyumba, maji karibu na nyumba, samani (furnished), swimming pool, na muda tangazo lilipowekwa (leo/wiki hii/mwezi huu/mwaka huu)
- Kuhifadhi nyumba unazozipenda kwenye "Zilizohifadhiwa" (Favorites)
- Kuwasiliana na mwenye nyumba baada ya kuingia (login) kwenye ukurasa wa maelezo ya nyumba
- Kwa wenye nyumba (seller): kuweka tangazo jipya la nyumba - inahitaji picha 3 za nyumba, hati ya umiliki, maelezo kamili, eneo la nyumba (linawekwa kiotomatiki kupitia GPS ya simu kwa kubonyeza "Weka eneo"), na malipo ya tangazo TZS 10,000; tangazo hupitiwa na kuthibitishwa ndani ya masaa 24
- Akaunti: kujisajili na kuingia (login) kama Mpangaji/Mnunuzi au Muuzaji/Mpangishaji
- Dashibodi ya muuzaji: kuona idadi ya matangazo (jumla, yaliyoidhinishwa, yanayopitiwa)

MAAGIZO MUHIMU - FUATA KWA UKAMILIFU:
1. Jibu maswali kuhusu huduma za Nyumba Mkononi PEKEE - jinsi ya kutafuta nyumba, kuweka tangazo, kutumia vichujio, kuhifadhi nyumba, kuwasiliana na wenye nyumba, akaunti, malipo ya tangazo, na mambo mengine yanayohusiana moja kwa moja na jukwaa hili.
2. USIJIBU swali lolote lisilohusiana na Nyumba Mkononi (mfano: habari za dunia, michezo, siasa, teknolojia nyingine, ushauri wa maisha, hesabu, tafsiri, au mada nyingine yoyote nje ya huduma za jukwaa hili). Kama swali haliambatani na huduma za jukwaa hili, sema kwa upole kwamba unaweza kusaidia tu na mambo yanayohusu Nyumba Mkononi, kisha muulize mtumiaji kama ana swali kuhusu jukwaa hili.
3. Jibu kwa Kiswahili pekee, kwa ufupi, uwazi na heshima, ukitumia sentensi fupi au orodha fupi pale inapohitajika.
4. Usibuni taarifa ambazo hujazipewa hapa (kwa mfano bei za huduma nyingine, sera ambazo hazijatajwa). Kama hujui jibu kamili, sema wazi na mshauri awasiliane na msaada zaidi.
"""


class ChatMessageIn(BaseModel):
    role: str = Field(pattern="^(user|assistant)$")
    content: str


class ChatRequest(BaseModel):
    messages: list[ChatMessageIn]


class ChatResponse(BaseModel):
    content: str


@router.post("/chat", response_model=ChatResponse)
async def ai_chat(payload: ChatRequest):
    if not settings.groq_api_key:
        raise HTTPException(
            status_code=503,
            detail="Msaidizi wa AI hajawekewa GROQ_API_KEY bado kwenye backend.",
        )

    messages = [{"role": "system", "content": _SYSTEM_PROMPT}] + [
        message.model_dump() for message in payload.messages
    ]

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(
            _GROQ_URL,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {settings.groq_api_key}",
            },
            json={"model": _GROQ_MODEL, "messages": messages, "temperature": 0.4},
        )

    if response.status_code >= 400:
        raise HTTPException(
            status_code=502,
            detail=f"Imeshindikana kuwasiliana na msaidizi (Groq {response.status_code}).",
        )

    data = response.json()
    try:
        content = data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError):
        raise HTTPException(status_code=502, detail="Jibu la msaidizi halikueleweka.") from None

    return ChatResponse(content=content.strip())
