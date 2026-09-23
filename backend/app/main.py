import logging
from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import uuid4

from fastapi import Depends, FastAPI, File, Form, HTTPException, Query, Request, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import and_, func, or_, select, text, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

import cloudinary
import cloudinary.uploader

from .admin import router as admin_router
from .ai_assistant import router as ai_router
from .payments import router as payments_router
from .auth import create_access_token, get_current_user, hash_password, verify_password
from .database import Base, engine, get_db, settings
from .models import Feedback, Favorite, LoginEvent, Message, Notification, Payment, PaymentStatus, Property, PropertyMode, PropertyStatus, PropertyType, User, UserRole
from .schemas import (
    AuthResponse,
    ConversationResponse,
    FeedbackCreate,
    FavoriteResponse,
    LoginRequest,
    MessageCreate,
    MessageResponse,
    NotificationResponse,
    PropertyResponse,
    PropertyUpdate,
    PropertyWithOwnerResponse,
    PublicPropertyResponse,
    UserCreate,
    UserResponse,
    UserUpdate,
)

logger = logging.getLogger("nyumba_mkononi")

BASE_DIR = Path(__file__).resolve().parent.parent
UPLOADS_DIR = BASE_DIR / "uploads"
UPLOADS_DIR.mkdir(exist_ok=True)

app = FastAPI(title="Nyumba Mkononi API", version="1.0.0")
app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")
app.include_router(admin_router)
app.include_router(payments_router)
app.include_router(ai_router)

cloudinary.config(
    cloud_name=settings.cloudinary_cloud_name,
    api_key=settings.cloudinary_api_key,
    api_secret=settings.cloudinary_api_secret,
    secure=True,
)

origins = [origin.strip() for origin in settings.cors_origins.split(",") if origin.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def _unhandled_exception_handler(request: Request, exc: Exception):
    """Bila hii, exception yoyote isiyoshikwa ndani ya endpoint (mfano
    httpx.ConnectError kwenda ClickPesa, IntegrityError ya database,
    n.k.) inasababisha 500 ambayo inapita NJE ya CORSMiddleware -
    browser haipati Access-Control-Allow-Origin header kabisa na
    inaripoti "blocked by CORS policy" ingawa CORS haihusiki. Handler
    hii inahakikisha hata error zisizotarajiwa zinarudisha header sahihi
    ili frontend ipate ujumbe wa kawaida wa 500 badala ya kufeli kimya.

    Tunaandika (log) traceback halisi hapa kabla ya kurudisha ujumbe wa
    jumla - bila hii ujumbe halisi wa error (mfano jina la column
    lisilopo kwenye DB, au Cloudinary kukataa credentials) unapotea kabisa
    na hauonekani popote, na kufanya idhibiti kuwa vigumu. Angalia logs za
    server (Render/Railway n.k.) kuona traceback hii."""
    logger.exception("Unhandled error on %s %s", request.method, request.url.path, exc_info=exc)
    origin = request.headers.get("origin")
    headers = {}
    if origin and origin in origins:
        headers["Access-Control-Allow-Origin"] = origin
        headers["Access-Control-Allow-Credentials"] = "true"
    return JSONResponse(
        status_code=500,
        content={"detail": "Hitilafu ya ndani ya server. Jaribu tena baadaye."},
        headers=headers,
    )


@app.on_event("startup")
def create_tables() -> None:
    # `create_all` inaunda majedwali MAPYA tu (mfano `notifications`) - haiwezi
    # kuongeza column mpya kwenye jedwali `users` ambalo tayari lipo kwenye
    # database ya production. Kwa hiyo tunaongeza column hiyo wenyewe hapa,
    # kwa amri isiyo na madhara ikiwa tayari ipo (IF NOT EXISTS) - inafanya
    # kazi salama kila mara app inapoanza, bila hatua yoyote ya mkono kwenye
    # server halisi.
    Base.metadata.create_all(bind=engine)
    with engine.begin() as connection:
        connection.execute(text(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_picha_url VARCHAR(500)"
        ))


def ensure_seller(user: User) -> None:
    if user.role != UserRole.SELLER:
        raise HTTPException(status_code=403, detail="Hatua hii ni ya seller pekee")


def public_property_filter():
    now = datetime.now(timezone.utc)
    return and_(
        Property.status == PropertyStatus.APPROVED,
        (Property.expires_at.is_(None) | (Property.expires_at > now)),
    )


def posted_within_cutoff(value: str) -> datetime | None:
    now = datetime.now(timezone.utc)
    if value == "today":
        return now.replace(hour=0, minute=0, second=0, microsecond=0)
    if value == "week":
        return now - timedelta(days=7)
    if value == "month":
        return now - timedelta(days=30)
    if value == "year":
        return now - timedelta(days=365)
    return None


async def save_upload(upload: UploadFile, folder: str) -> str:
    extension = Path(upload.filename or "").suffix.lower()
    allowed_extensions = {".jpg", ".jpeg", ".png", ".webp", ".pdf"}
    if extension not in allowed_extensions:
        raise HTTPException(status_code=400, detail="Aina ya file hairuhusiwi")
    if not (settings.cloudinary_cloud_name and settings.cloudinary_api_key and settings.cloudinary_api_secret):
        # Env variables CLOUDINARY_CLOUD_NAME / CLOUDINARY_API_KEY /
        # CLOUDINARY_API_SECRET hazijawekwa (au ziko tupu) kwenye server -
        # bila hizi, cloudinary.uploader.upload() inashindwa kila mara na
        # inakuwa 500 isiyoeleweka upande wa app. Tunakagua mapema na
        # kutoa ujumbe wa wazi badala yake.
        logger.error("Cloudinary haijawekewa mipangilio - CLOUDINARY_CLOUD_NAME/API_KEY/API_SECRET hazipo kwenye env ya server.")
        raise HTTPException(status_code=500, detail="Upakiaji wa picha haujawekewa mipangilio kwenye server. Wasiliana na msimamizi wa mfumo.")
    contents = await upload.read()
    resource_type = "raw" if extension == ".pdf" else "image"
    try:
        result = cloudinary.uploader.upload(
            contents,
            folder=f"nyumba_mkononi/{folder}",
            resource_type=resource_type,
            public_id=uuid4().hex,
        )
    except Exception:
        logger.exception("Cloudinary upload imeshindikana (folder=%s, filename=%s)", folder, upload.filename)
        raise HTTPException(status_code=502, detail="Imeshindikana kupakia faili. Jaribu tena baadaye.")
    return result["secure_url"]


@app.post("/auth/register", response_model=AuthResponse, status_code=201)
def register(payload: UserCreate, db: Session = Depends(get_db)):
    if db.scalar(select(User).where(User.username == payload.username)):
        raise HTTPException(status_code=409, detail="Username tayari ipo")
    user = User(
        jina_kamili=payload.jina_kamili,
        namba_ya_simu=payload.namba_ya_simu,
        username=payload.username,
        password_hash=hash_password(payload.password),
        role=payload.role,
        email=str(payload.email) if payload.email else None,
        eneo=payload.eneo,
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Username tayari ipo") from None
    db.refresh(user)
    db.add(Notification(
        user_id=user.id,
        title="Karibu Nyumba Mkononi!",
        body=f"Habari {user.jina_kamili}, akaunti yako imefunguliwa kikamilifu. Karibu utafute au utangaze nyumba.",
    ))
    db.commit()
    return AuthResponse(access_token=create_access_token(user), user=user)


@app.post("/auth/login", response_model=AuthResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.username == payload.username))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Username au password si sahihi")
    db.add(LoginEvent(user_id=user.id, role=user.role))
    db.commit()
    return AuthResponse(access_token=create_access_token(user), user=user)


# --- Taarifa binafsi za mtumiaji aliyeautheticate (wasifu) --------------

@app.get("/auth/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """Taarifa zote binafsi za mtumiaji, kama alivyoziingiza wakati wa
    usajili, kwa ajili ya sehemu ya 'Taarifa binafsi' kwenye wasifu."""
    return current_user


@app.patch("/auth/me", response_model=UserResponse)
def update_me(payload: UserUpdate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Mtumiaji anahariri taarifa zake binafsi (jina, simu, email, eneo)."""
    data = payload.model_dump(exclude_unset=True)
    if "jina_kamili" in data and data["jina_kamili"] is not None:
        current_user.jina_kamili = data["jina_kamili"]
    if "namba_ya_simu" in data and data["namba_ya_simu"] is not None:
        current_user.namba_ya_simu = data["namba_ya_simu"]
    if "email" in data:
        current_user.email = str(data["email"]) if data["email"] else None
    if "eneo" in data:
        current_user.eneo = data["eneo"]
    db.commit()
    db.refresh(current_user)
    return current_user


@app.post("/auth/me/photo", response_model=UserResponse)
async def update_my_photo(
    photo: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mtumiaji anapakia/anabadilisha profile picha yake."""
    photo_url = await save_upload(photo, "profile-pictures")
    current_user.profile_picha_url = photo_url
    db.commit()
    db.refresh(current_user)
    return current_user


@app.post("/feedback", status_code=201)
def create_feedback(
    payload: FeedbackCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    feedback = Feedback(user_id=current_user.id, message=payload.message)
    db.add(feedback)
    db.commit()
    return {"message": "Maoni yamepokelewa"}


# --- Public-facing property endpoints ---------------------------------
# Hizi zinatumia PublicPropertyResponse (HAINA verification_doc_url)
# kwa sababu zinaweza kufikiwa na buyer yeyote, hata bila kuwa
# ameautheticate. Hati ya uthibitisho ni taarifa nyeti - haipaswi
# kuvuja kwa umma.

@app.get("/properties", response_model=list[PublicPropertyResponse])
def list_properties(
    location: str | None = None,
    min_price: int | None = Query(default=None, ge=0),
    max_price: int | None = Query(default=None, ge=0),
    property_type: PropertyType | None = None,
    mode: PropertyMode | None = None,
    has_wifi: bool | None = None,
    car_parking: bool | None = None,
    indoor_toilet: bool | None = None,
    has_electricity: bool | None = None,
    water_inside: bool | None = None,
    water_nearby: bool | None = None,
    furnished: bool | None = None,
    swimming_pool: bool | None = None,
    posted_within: str | None = Query(default=None, pattern="^(today|week|month|year)$"),
    db: Session = Depends(get_db),
):
    # Idadi ya favorites kwa kila property - inatumika kupanga matokeo
    # ya default (bila filter) kuanzia yaliyopendwa zaidi.
    fav_count_subq = (
        select(Favorite.property_id, func.count(Favorite.id).label("fav_count"))
        .group_by(Favorite.property_id)
        .subquery()
    )

    query = (
        select(Property)
        .outerjoin(fav_count_subq, fav_count_subq.c.property_id == Property.id)
        .where(public_property_filter())
    )
    if location:
        query = query.where(Property.location_label.ilike(f"%{location}%"))
    if min_price is not None:
        query = query.where(Property.price >= min_price)
    if max_price is not None:
        query = query.where(Property.price <= max_price)
    if property_type is not None:
        query = query.where(Property.aina == property_type)
    if mode is not None:
        query = query.where(Property.mode == mode)
    if has_wifi is not None:
        query = query.where(Property.has_wifi == has_wifi)
    if car_parking is not None:
        query = query.where(Property.car_parking == car_parking)
    if indoor_toilet is not None:
        query = query.where(Property.indoor_toilet == indoor_toilet)
    if has_electricity is not None:
        query = query.where(Property.has_electricity == has_electricity)
    if water_inside is not None:
        query = query.where(Property.water_inside == water_inside)
    if water_nearby is not None:
        query = query.where(Property.water_nearby == water_nearby)
    if furnished is not None:
        query = query.where(Property.furnished == furnished)
    if swimming_pool is not None:
        query = query.where(Property.swimming_pool == swimming_pool)
    if posted_within is not None:
        cutoff = posted_within_cutoff(posted_within)
        if cutoff is not None:
            query = query.where(Property.created_at >= cutoff)

    # Algorithm ya kupanga: zilizopendwa zaidi (favorites), kisha
    # zilizoangaliwa zaidi (view_count), kisha mpya zaidi. Hii inatumika
    # kama default (mtumiaji hajaweka filter) na pia kama tiebreaker
    # anapotumia filters.
    query = query.order_by(
        func.coalesce(fav_count_subq.c.fav_count, 0).desc(),
        Property.view_count.desc(),
        Property.created_at.desc(),
    )
    return list(db.scalars(query).unique().all())


@app.get("/properties/{property_id}", response_model=PublicPropertyResponse)
def get_property(property_id: int, db: Session = Depends(get_db)):
    property_item = db.scalar(select(Property).where(Property.id == property_id, public_property_filter()))
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    property_item.view_count += 1
    db.commit()
    db.refresh(property_item)
    return property_item


# --- Owner contact info (kwa sehemu ya "eneo la nyumba" / mawasiliano) --

@app.get("/properties/{property_id}/contact", response_model=PropertyWithOwnerResponse)
def get_property_contact(property_id: int, db: Session = Depends(get_db)):
    property_item = db.scalar(
        select(Property).options(joinedload(Property.owner)).where(Property.id == property_id, public_property_filter())
    )
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    base = PublicPropertyResponse.model_validate(property_item).model_dump()
    return PropertyWithOwnerResponse(
        **base,
        owner_jina=property_item.owner.jina_kamili,
        owner_simu=property_item.owner.namba_ya_simu,
        owner_email=property_item.owner.email,
    )


# --- Messages (chat kati ya buyer na seller kuhusu tangazo maalum) -----

@app.post("/properties/{property_id}/messages", response_model=MessageResponse, status_code=201)
def send_message(
    property_id: int,
    payload: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    property_item = db.get(Property, property_id)
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    if current_user.id == property_item.owner_id:
        if payload.receiver_id is None:
            raise HTTPException(status_code=400, detail="receiver_id inahitajika kwa mmiliki")
        receiver_id = payload.receiver_id
    else:
        receiver_id = property_item.owner_id
    message = Message(
        property_id=property_id,
        sender_id=current_user.id,
        receiver_id=receiver_id,
        content=payload.content,
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    return message


@app.get("/properties/{property_id}/messages", response_model=list[MessageResponse])
def get_messages(
    property_id: int,
    with_user_id: int | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    property_item = db.get(Property, property_id)
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    other_id = with_user_id
    if other_id is None:
        if current_user.id != property_item.owner_id:
            other_id = property_item.owner_id
        else:
            raise HTTPException(status_code=400, detail="with_user_id inahitajika")
    query = (
        select(Message)
        .where(
            Message.property_id == property_id,
            or_(
                and_(Message.sender_id == current_user.id, Message.receiver_id == other_id),
                and_(Message.sender_id == other_id, Message.receiver_id == current_user.id),
            ),
        )
        .order_by(Message.created_at.asc())
    )
    messages = list(db.scalars(query).all())
    unread_ids = [m.id for m in messages if m.receiver_id == current_user.id and m.read_at is None]
    if unread_ids:
        db.execute(update(Message).where(Message.id.in_(unread_ids)).values(read_at=func.now()))
        db.commit()
        now = datetime.now(timezone.utc)
        for m in messages:
            if m.id in unread_ids:
                m.read_at = now
    return messages


# --- Inbox ya mazungumzo (kwa mpangishaji/mnunuzi kuona ujumbe wote) ----
# Inarudisha "threads" - kikundi kimoja kwa kila (tangazo, mtu mwingine) -
# kikiwa na ujumbe wa mwisho na idadi ya usiosomwa. Hii ndiyo "taarifa za
# kweli" mpangishaji anazoziona kuhusu ujumbe unaomsubiri.

def _conversation_threads(current_user: User, db: Session) -> list[dict]:
    """Muhtasari wa mazungumzo ya mtumiaji, kimoja kwa kila (tangazo, mtu
    mwingine) - kinatumika kwenye inbox ya ujumbe NA kwenye /notifications
    (kama 'arifa kutoka kwa mmiliki wa nyumba')."""
    query = (
        select(Message)
        .options(joinedload(Message.sender), joinedload(Message.receiver), joinedload(Message.property))
        .where(or_(Message.sender_id == current_user.id, Message.receiver_id == current_user.id))
        .order_by(Message.created_at.asc())
    )
    messages = list(db.scalars(query).unique().all())
    threads: dict[tuple[int, int], dict] = {}
    for message in messages:
        other = message.receiver if message.sender_id == current_user.id else message.sender
        key = (message.property_id, other.id)
        thread = threads.get(key)
        if thread is None:
            thread = {
                "property_id": message.property_id,
                "property_name": message.property.jina if message.property else "",
                "other_user_id": other.id,
                "other_user_name": other.jina_kamili,
                "last_message": message.content,
                "last_message_at": message.created_at,
                "last_sender_id": message.sender_id,
                "unread_count": 0,
            }
            threads[key] = thread
        else:
            thread["last_message"] = message.content
            thread["last_message_at"] = message.created_at
            thread["last_sender_id"] = message.sender_id
        if message.receiver_id == current_user.id and message.read_at is None:
            thread["unread_count"] += 1
    return sorted(threads.values(), key=lambda item: item["last_message_at"], reverse=True)


@app.get("/messages/conversations", response_model=list[ConversationResponse])
def list_conversations(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return _conversation_threads(current_user, db)


@app.delete("/messages/{message_id}", status_code=204)
def delete_message(message_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    message = db.get(Message, message_id)
    if message is None:
        raise HTTPException(status_code=404, detail="Ujumbe haukupatikani")
    if current_user.id not in (message.sender_id, message.receiver_id):
        raise HTTPException(status_code=403, detail="Huna ruhusa kufuta ujumbe huu")
    db.delete(message)
    db.commit()


# --- Seller-only property endpoints ------------------------------------
# Hizi zinatumia PropertyResponse kamili (INA verification_doc_url)
# kwa sababu ni seller mwenyewe, aliyeauthenticate, akiona taarifa zake.

@app.post("/properties", response_model=PropertyResponse, status_code=201)
async def create_property(
    jina: str = Form(...),
    aina: PropertyType = Form(...),
    mode: PropertyMode = Form(...),
    price: int = Form(..., ge=0),
    location_label: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    has_wifi: bool = Form(False),
    car_parking: bool = Form(False),
    indoor_toilet: bool = Form(False),
    has_electricity: bool = Form(False),
    water_inside: bool = Form(False),
    water_nearby: bool = Form(False),
    furnished: bool = Form(False),
    swimming_pool: bool = Form(False),
    description: str = Form(...),
    payment_ref: str = Form(..., description="tx_ref ya malipo ya ada ya TZS 5,000 (kutoka /payments/listing-fee/initiate)"),
    photos: list[UploadFile] = File(...),
    verification_doc: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ensure_seller(current_user)
    if len(photos) != 3:
        raise HTTPException(status_code=400, detail="Tuma picha 3 za nyumba")

    # --- Hakikisha ada ya TZS 5,000 imelipwa kabla ya kupokea tangazo ---
    # Tangazo halikubaliwi bila malipo halisi, yaliyothibitishwa na
    # ClickPesa, na tx_ref moja haiwezi kutumika kwenye matangazo
    # mawili (property_id ikishawekwa, tx_ref hiyo "imeisha").
    payment = db.scalar(select(Payment).where(Payment.tx_ref == payment_ref))
    if payment is None or payment.user_id != current_user.id:
        raise HTTPException(status_code=402, detail="Malipo hayakupatikana. Lipa TZS 5,000 kwanza kabla ya kutuma tangazo.")
    if payment.status != PaymentStatus.SUCCESSFUL:
        raise HTTPException(status_code=402, detail="Malipo ya TZS 5,000 hayajakamilika bado. Kamilisha malipo kisha jaribu tena.")
    if payment.property_id is not None:
        raise HTTPException(status_code=409, detail="Malipo haya tayari yametumika kwenye tangazo lingine.")

    photo_urls = [await save_upload(photo, "properties") for photo in photos]
    verification_doc_url = await save_upload(verification_doc, "verification-docs")
    property_item = Property(
        owner_id=current_user.id,
        jina=jina,
        aina=aina,
        mode=mode,
        price=price,
        location_label=location_label,
        latitude=latitude,
        longitude=longitude,
        has_wifi=has_wifi,
        car_parking=car_parking,
        indoor_toilet=indoor_toilet,
        has_electricity=has_electricity,
        water_inside=water_inside,
        water_nearby=water_nearby,
        furnished=furnished,
        swimming_pool=swimming_pool,
        description=description,
        photo_urls=photo_urls,
        verification_doc_url=verification_doc_url,
        status=PropertyStatus.PENDING,
    )
    db.add(property_item)
    db.commit()
    db.refresh(property_item)

    # Funga malipo haya kwa tangazo hili ili yasitumike tena.
    payment.property_id = property_item.id
    db.commit()

    return property_item


@app.get("/properties/mine", response_model=list[PropertyResponse])
def list_my_properties(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ensure_seller(current_user)
    # Idadi ya "like" (favorites) kwa kila tangazo, na idadi ya ujumbe
    # usiosomwa uliopokelewa na mpangishaji kwa kila tangazo - hivi
    # ndivyo "notifications za kweli" anazoziona kwenye dashibodi yake.
    fav_count_subq = (
        select(Favorite.property_id, func.count(Favorite.id).label("fav_count"))
        .group_by(Favorite.property_id)
        .subquery()
    )
    unread_subq = (
        select(Message.property_id, func.count(Message.id).label("unread_count"))
        .where(Message.receiver_id == current_user.id, Message.read_at.is_(None))
        .group_by(Message.property_id)
        .subquery()
    )
    query = (
        select(
            Property,
            func.coalesce(fav_count_subq.c.fav_count, 0),
            func.coalesce(unread_subq.c.unread_count, 0),
        )
        .outerjoin(fav_count_subq, fav_count_subq.c.property_id == Property.id)
        .outerjoin(unread_subq, unread_subq.c.property_id == Property.id)
        .where(Property.owner_id == current_user.id)
        .order_by(Property.created_at.desc())
    )
    results: list[PropertyResponse] = []
    for property_item, fav_count, unread_count in db.execute(query).all():
        data = PropertyResponse.model_validate(property_item).model_dump()
        data["favorites_count"] = fav_count
        data["unread_messages_count"] = unread_count
        results.append(PropertyResponse(**data))
    return results


def _get_own_property(property_id: int, current_user: User, db: Session) -> Property:
    """Inapata tangazo kwa ID na kuhakikisha ni la mwenye tangazo mwenyewe
    (seller aliyeautheticate) - vinginevyo 404 (siyo 403, ili tusifichue
    kuwepo kwa tangazo la mtu mwingine)."""
    ensure_seller(current_user)
    property_item = db.get(Property, property_id)
    if property_item is None or property_item.owner_id != current_user.id:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    return property_item


@app.patch("/properties/{property_id}", response_model=PropertyResponse)
def update_my_property(
    property_id: int,
    payload: PropertyUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mwenye tangazo (seller) anahariri taarifa za tangazo lake mwenyewe -
    jina, bei, maelezo, huduma zilizopo na eneo. Picha na hati ya
    uthibitisho hazibadilishwi hapa (ni za kudumu tangu kuunda tangazo)."""
    property_item = _get_own_property(property_id, current_user, db)
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(property_item, field, value)
    db.commit()
    db.refresh(property_item)
    # Rudisha na idadi za favorites/unread halisi, kama vile /properties/mine,
    # ili UI ya dashibodi isionyeshe 0 baada ya kuhariri.
    fav_count = db.scalar(select(func.count(Favorite.id)).where(Favorite.property_id == property_item.id)) or 0
    unread_count = db.scalar(
        select(func.count(Message.id)).where(
            Message.property_id == property_item.id,
            Message.receiver_id == current_user.id,
            Message.read_at.is_(None),
        )
    ) or 0
    result = PropertyResponse.model_validate(property_item).model_dump()
    result["favorites_count"] = fav_count
    result["unread_messages_count"] = unread_count
    return PropertyResponse(**result)


@app.delete("/properties/{property_id}", status_code=204)
def delete_my_property(
    property_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mwenye tangazo (seller) anafuta tangazo lake mwenyewe kabisa kutoka
    kwenye mfumo (favorites na messages zinazohusiana zinafutika pia -
    cascade). Hatua ya kudumu, haiwezi kutendulika."""
    property_item = _get_own_property(property_id, current_user, db)
    db.delete(property_item)
    db.commit()


# --- Favorites -----------------------------------------------------------

@app.get("/favorites", response_model=list[FavoriteResponse])
def list_favorites(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    query = (
        select(Favorite)
        .options(joinedload(Favorite.property))
        .where(Favorite.user_id == current_user.id)
        .order_by(Favorite.created_at.desc())
    )
    return list(db.scalars(query).unique().all())


@app.post("/favorites/{property_id}", response_model=FavoriteResponse, status_code=201)
def add_favorite(property_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    property_item = db.scalar(select(Property).where(Property.id == property_id, public_property_filter()))
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    existing = db.scalar(select(Favorite).where(Favorite.user_id == current_user.id, Favorite.property_id == property_id))
    if existing:
        raise HTTPException(status_code=409, detail="Tangazo tayari liko kwenye favorites")
    favorite = Favorite(user_id=current_user.id, property_id=property_id)
    db.add(favorite)
    db.commit()
    db.refresh(favorite)
    favorite.property = property_item
    return favorite


@app.delete("/favorites/{property_id}", status_code=204)
def remove_favorite(property_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    favorite = db.scalar(select(Favorite).where(Favorite.user_id == current_user.id, Favorite.property_id == property_id))
    if favorite is None:
        raise HTTPException(status_code=404, detail="Favorite haikupatikana")
    db.delete(favorite)
    db.commit()


# --- Arifa (notifications) ----------------------------------------------
# Inaunganisha aina mbili za arifa kwenye orodha moja: (1) arifa za
# 'platform' (mfano: tangazo limeruhusiwa/limekataliwa, karibu) kutoka
# kwenye jedwali la Notification, na (2) muhtasari wa ujumbe kutoka kwa
# mmiliki wa nyumba / mnunuzi (conversations) - hivi ndivyo mtumiaji
# anavyoona "Arifa" zote kwenye sehemu ya wasifu.

@app.get("/notifications", response_model=list[NotificationResponse])
def list_notifications(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    items: list[NotificationResponse] = []

    platform_rows = db.scalars(
        select(Notification)
        .where(Notification.user_id == current_user.id)
        .order_by(Notification.created_at.desc())
    ).all()
    for row in platform_rows:
        items.append(NotificationResponse(
            id=f"platform-{row.id}",
            type="platform",
            title=row.title,
            body=row.body,
            created_at=row.created_at,
            read=row.read_at is not None,
            property_id=row.property_id,
        ))

    for thread in _conversation_threads(current_user, db):
        items.append(NotificationResponse(
            id=f"owner-{thread['property_id']}-{thread['other_user_id']}",
            type="owner",
            title=f"Ujumbe kutoka kwa {thread['other_user_name']}",
            body=thread["last_message"],
            created_at=thread["last_message_at"],
            read=thread["unread_count"] == 0,
            property_id=thread["property_id"],
            property_name=thread["property_name"],
            other_user_id=thread["other_user_id"],
        ))

    items.sort(key=lambda item: item.created_at, reverse=True)
    return items


@app.post("/notifications/{notification_id}/read", response_model=NotificationResponse)
def mark_notification_read(notification_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not notification_id.startswith("platform-"):
        raise HTTPException(status_code=400, detail="Arifa za ujumbe zinasomwa kwa kufungua mazungumzo husika")
    try:
        real_id = int(notification_id.split("-", 1)[1])
    except (IndexError, ValueError):
        raise HTTPException(status_code=400, detail="ID ya arifa si sahihi") from None
    row = db.get(Notification, real_id)
    if row is None or row.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Arifa haikupatikana")
    if row.read_at is None:
        row.read_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(row)
    return NotificationResponse(
        id=f"platform-{row.id}",
        type="platform",
        title=row.title,
        body=row.body,
        created_at=row.created_at,
        read=row.read_at is not None,
        property_id=row.property_id,
    )


@app.get("/health")
def health_check():
    return {"status": "ok"}
