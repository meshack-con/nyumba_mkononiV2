"""Admin routes - request za kupitisha/kukataa matangazo ya nyumba,
na analytics ya dashboard (akaunti mpya na logins kwa muda mbalimbali).

Router hii yote inalindwa na `ensure_admin` - mtumiaji lazima awe
ameautheticate NA awe `is_admin=True`.
"""
import re
from collections import defaultdict
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from pydantic import EmailStr, TypeAdapter, ValidationError
from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .auth import ensure_admin, hash_password
from .database import get_db
from .models import LoginEvent, Notification, Property, PropertyMode, PropertyStatus, PropertyType, User, UserRole
from .schemas import AnalyticsPoint, AnalyticsSummary, PropertyResponse, UserResponse

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(ensure_admin)])


# --- Helpers ----------------------------------------------------------

def _period_starts(now: datetime) -> dict[str, datetime]:
    """Mwanzo wa 'leo', 'wiki hii' (Jumatatu), 'mwezi huu', na 'mwaka huu'."""
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = today_start - timedelta(days=today_start.weekday())
    month_start = today_start.replace(day=1)
    year_start = today_start.replace(month=1, day=1)
    return {"today": today_start, "week": week_start, "month": month_start, "year": year_start}


def _count(db: Session, model, *filters) -> int:
    query = select(func.count()).select_from(model)
    for f in filters:
        query = query.where(f)
    return db.scalar(query) or 0


# --- Property moderation ------------------------------------------------

@router.get("/properties/pending", response_model=list[PropertyResponse])
def list_pending_properties(db: Session = Depends(get_db)):
    """Matangazo yanayosubiri uamuzi wa admin - pamoja na picha na
    verification_doc_url (admin anahitaji kuona kila kitu ili kuamua)."""
    query = (
        select(Property)
        .where(Property.status == PropertyStatus.PENDING)
        .order_by(Property.created_at.asc())
    )
    return list(db.scalars(query).all())


@router.get("/properties", response_model=list[PropertyResponse])
def list_all_properties(status_filter: PropertyStatus | None = None, db: Session = Depends(get_db)):
    """Matangazo yote (historia kamili), yenye uwezo wa kuchuja kwa status."""
    query = select(Property).order_by(Property.created_at.desc())
    if status_filter is not None:
        query = query.where(Property.status == status_filter)
    return list(db.scalars(query).all())


@router.get("/properties/{property_id}", response_model=PropertyResponse)
def get_property_for_review(property_id: int, db: Session = Depends(get_db)):
    property_item = db.get(Property, property_id)
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    return property_item


@router.get("/users", response_model=list[UserResponse])
def search_users(q: str = "", db: Session = Depends(get_db)):
    """Tafuta akaunti zilizopo (kwa jina, username au namba ya simu) ili admin
    aweze kuongeza nyumba nyingine kwenye akaunti ya mmiliki aliyeshaundiwa.
    Inarudisha akaunti 20 za hivi karibuni kama `q` ni tupu. Akaunti za admin
    hazionyeshwi."""
    query = select(User).where(User.is_admin.is_not(True))
    term = q.strip()
    if term:
        like = f"%{term}%"
        query = query.where(
            or_(User.jina_kamili.ilike(like), User.username.ilike(like), User.namba_ya_simu.ilike(like))
        )
    return list(db.scalars(query.order_by(User.created_at.desc()).limit(20)).all())


@router.post("/properties", response_model=PropertyResponse, status_code=201)
async def admin_create_property(
    jina: str = Form(..., min_length=2, max_length=180),
    aina: PropertyType = Form(...),
    mode: PropertyMode = Form(...),
    price: int = Form(..., ge=0),
    location_label: str = Form(..., min_length=1, max_length=180),
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
    description: str = Form(..., min_length=1),
    # Mmiliki: AIDHA `owner_id` (akaunti iliyopo) AU taarifa za akaunti mpya
    # (owner_jina, owner_simu, owner_username, owner_password + hiari email/eneo).
    owner_id: int | None = Form(None),
    owner_jina: str | None = Form(None),
    owner_simu: str | None = Form(None),
    owner_username: str | None = Form(None),
    owner_password: str | None = Form(None),
    owner_email: str | None = Form(None),
    owner_eneo: str | None = Form(None),
    photos: list[UploadFile] = File(...),
    verification_doc: UploadFile | None = File(None),
    db: Session = Depends(get_db),
):
    """Admin anaweka nyumba kwa niaba ya mmiliki. Nyumba inakaa kwenye akaunti
    ya mmiliki (aliyepo au anayeundwa hapa hapa - akaunti mpya ni halisi,
    mmiliki anaweza kuingia nayo kwa username/password aliyopewa).

    Tofauti na `POST /properties` ya watumiaji: HAKUNA malipo ya ada (hakuna
    Payment), hati ya uthibitisho ni hiari, na tangazo linaingia moja kwa
    moja kama APPROVED - linaonekana kwa watumiaji mara moja."""
    # Import hapa (ndani ya function) ili kuepuka circular import - main.py
    # inaingiza router hii wakati wa kuanza.
    from .main import save_upload

    if len(photos) != 3:
        raise HTTPException(status_code=400, detail="Tuma picha 3 za nyumba")

    # --- Kagua mmiliki KABLA ya kupakia picha (ili tusipoteze upakiaji) ---
    owner: User | None = None
    new_owner: dict | None = None
    if owner_id is not None:
        owner = db.get(User, owner_id)
        if owner is None:
            raise HTTPException(status_code=404, detail="Akaunti ya mmiliki haipatikani")
    else:
        name = (owner_jina or "").strip()
        phone = (owner_simu or "").strip()
        username = (owner_username or "").strip()
        password = owner_password or ""
        email = (owner_email or "").strip() or None
        eneo = (owner_eneo or "").strip() or None
        if len(name) < 2 or len(name) > 150:
            raise HTTPException(status_code=400, detail="Weka jina kamili la mmiliki")
        if len(re.sub(r"\D", "", phone)) < 7 or len(phone) > 30:
            raise HTTPException(status_code=400, detail="Namba ya simu ya mmiliki si sahihi")
        if not 3 <= len(username) <= 50 or re.search(r"\s", username):
            raise HTTPException(status_code=400, detail="Username iwe herufi 3-50 bila nafasi")
        if not 8 <= len(password) <= 128:
            raise HTTPException(status_code=400, detail="Password iwe angalau herufi 8")
        if email is not None:
            try:
                TypeAdapter(EmailStr).validate_python(email)
            except ValidationError:
                raise HTTPException(status_code=400, detail="Barua pepe ya mmiliki si sahihi") from None
        if eneo is not None and len(eneo) > 150:
            raise HTTPException(status_code=400, detail="Eneo la mmiliki ni refu mno")
        if db.scalar(select(User).where(User.username == username)):
            raise HTTPException(status_code=409, detail="Username tayari ipo")
        new_owner = {"name": name, "phone": phone, "username": username, "password": password, "email": email, "eneo": eneo}

    # Pakia faili KWANZA - ikishindikana, hakuna akaunti wala tangazo
    # linalobaki kwenye database (akaunti na tangazo vinahifadhiwa pamoja).
    photo_urls = [await save_upload(photo, "properties") for photo in photos]
    verification_doc_url = ""
    if verification_doc is not None and verification_doc.filename:
        verification_doc_url = await save_upload(verification_doc, "verification-docs")

    if new_owner is not None:
        owner = User(
            jina_kamili=new_owner["name"],
            namba_ya_simu=new_owner["phone"],
            username=new_owner["username"],
            password_hash=hash_password(new_owner["password"]),
            role=UserRole.SELLER,
            email=new_owner["email"],
            eneo=new_owner["eneo"],
        )
        db.add(owner)
        db.flush()
        db.add(Notification(
            user_id=owner.id,
            title="Karibu Nyumba Mkononi!",
            body=f"Habari {owner.jina_kamili}, akaunti yako imefunguliwa na timu ya Nyumba Mkononi. Karibu utangaze au utafute nyumba.",
        ))

    assert owner is not None
    property_item = Property(
        owner_id=owner.id,
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
        status=PropertyStatus.APPROVED,
    )
    db.add(property_item)
    try:
        db.flush()
        db.add(Notification(
            user_id=owner.id,
            title="Tangazo lako limewekwa",
            body=f"Tangazo lako la '{property_item.jina}' limewekwa na timu ya Nyumba Mkononi na sasa linaonekana kwa umma.",
            property_id=property_item.id,
        ))
        db.commit()
    except IntegrityError:
        db.rollback()
        # Kesi adimu: username ilichukuliwa na mtu mwingine kati ya ukaguzi na kuhifadhi.
        raise HTTPException(status_code=409, detail="Username tayari ipo") from None
    db.refresh(property_item)
    return property_item


@router.post("/properties/{property_id}/approve", response_model=PropertyResponse)
def approve_property(property_id: int, db: Session = Depends(get_db)):
    property_item = db.get(Property, property_id)
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    if property_item.status == PropertyStatus.APPROVED:
        raise HTTPException(status_code=409, detail="Tangazo tayari limeruhusiwa")
    property_item.status = PropertyStatus.APPROVED
    db.add(Notification(
        user_id=property_item.owner_id,
        title="Tangazo lako limeruhusiwa",
        body=f"Tangazo lako la '{property_item.jina}' limepitishwa na sasa linaonekana kwa umma.",
        property_id=property_item.id,
    ))
    db.commit()
    db.refresh(property_item)
    return property_item


@router.post("/properties/{property_id}/reject", response_model=PropertyResponse)
def reject_property(property_id: int, db: Session = Depends(get_db)):
    property_item = db.get(Property, property_id)
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    if property_item.status == PropertyStatus.REJECTED:
        raise HTTPException(status_code=409, detail="Tangazo tayari limekataliwa")
    property_item.status = PropertyStatus.REJECTED
    db.add(Notification(
        user_id=property_item.owner_id,
        title="Tangazo lako halikuruhusiwa",
        body=f"Tangazo lako la '{property_item.jina}' limekataliwa. Wasiliana na msaada kwa maelezo zaidi.",
        property_id=property_item.id,
    ))
    db.commit()
    db.refresh(property_item)
    return property_item


@router.delete("/properties/{property_id}", status_code=204)
def delete_property(property_id: int, db: Session = Depends(get_db)):
    """Admin anafuta tangazo la nyumba kabisa kutoka kwenye mfumo - hii ni
    hatua ya kudumu (favorites na messages zinazohusiana zinafutika pia).

    Tofauti na reject (ambayo inabaki kwenye historia ikiwa 'rejected'),
    delete inaondoa rekodi kabisa - inafaa kwa matangazo ya udanganyifu,
    marudio, au maombi ya moja kwa moja ya mwenye tangazo/admin kufuta."""
    property_item = db.get(Property, property_id)
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    db.delete(property_item)
    db.commit()
    return None


# --- Analytics dashboard -------------------------------------------------

@router.get("/analytics/summary", response_model=AnalyticsSummary)
def analytics_summary(db: Session = Depends(get_db)):
    """Namba za muhtasari kwa dashboard: jumla za akaunti, matangazo
    yanayosubiri, na idadi ya registrations/logins kwa kila kipindi."""
    now = datetime.now(timezone.utc)
    starts = _period_starts(now)

    total_buyers = _count(db, User, User.role == UserRole.BUYER)
    total_sellers = _count(db, User, User.role == UserRole.SELLER)
    total_users = total_buyers + total_sellers
    pending_properties = _count(db, Property, Property.status == PropertyStatus.PENDING)

    return AnalyticsSummary(
        total_buyers=total_buyers,
        total_sellers=total_sellers,
        total_users=total_users,
        pending_properties=pending_properties,
        registrations_today=_count(db, User, User.created_at >= starts["today"]),
        registrations_this_week=_count(db, User, User.created_at >= starts["week"]),
        registrations_this_month=_count(db, User, User.created_at >= starts["month"]),
        registrations_this_year=_count(db, User, User.created_at >= starts["year"]),
        logins_today=_count(db, LoginEvent, LoginEvent.created_at >= starts["today"]),
        logins_this_week=_count(db, LoginEvent, LoginEvent.created_at >= starts["week"]),
        logins_this_month=_count(db, LoginEvent, LoginEvent.created_at >= starts["month"]),
        logins_this_year=_count(db, LoginEvent, LoginEvent.created_at >= starts["year"]),
    )


@router.get("/analytics/registrations-by-month", response_model=list[AnalyticsPoint])
def registrations_by_month(months: int = 12, db: Session = Depends(get_db)):
    """Data ya line chart - akaunti mpya (buyer/seller/total) kwa kila
    mwezi, kuanzia miezi `months` iliyopita hadi mwezi huu. Miezi
    isiyo na akaunti mpya inaonyeshwa kama 0 (chart haivunjiki)."""
    if months < 1 or months > 60:
        raise HTTPException(status_code=400, detail="months lazima iwe kati ya 1 na 60")

    now = datetime.now(timezone.utc)
    first_of_this_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    since = first_of_this_month
    for _ in range(months - 1):
        since = (since - timedelta(days=1)).replace(day=1)

    rows = db.scalars(select(User).where(User.created_at >= since)).all()

    buckets: dict[str, dict[str, int]] = defaultdict(lambda: {"buyer": 0, "seller": 0, "total": 0})
    for user in rows:
        key = user.created_at.strftime("%Y-%m")
        buckets[key]["total"] += 1
        if user.role == UserRole.BUYER:
            buckets[key]["buyer"] += 1
        else:
            buckets[key]["seller"] += 1

    points: list[AnalyticsPoint] = []
    cursor = since
    for _ in range(months):
        key = cursor.strftime("%Y-%m")
        data = buckets.get(key, {"buyer": 0, "seller": 0, "total": 0})
        points.append(AnalyticsPoint(period=key, buyer=data["buyer"], seller=data["seller"], total=data["total"]))
        cursor = (cursor.replace(day=28) + timedelta(days=4)).replace(day=1)

    return points


@router.get("/analytics/logins-by-period")
def logins_by_period(db: Session = Depends(get_db)) -> dict[str, dict[str, int]]:
    """Mgawanyo wa logins (jumla, buyer, seller) kwa siku/wiki/mwezi/mwaka."""
    now = datetime.now(timezone.utc)
    starts = _period_starts(now)
    result: dict[str, dict[str, int]] = {}
    for label, since in starts.items():
        result[label] = {
            "total": _count(db, LoginEvent, LoginEvent.created_at >= since),
            "buyer": _count(db, LoginEvent, LoginEvent.created_at >= since, LoginEvent.role == UserRole.BUYER),
            "seller": _count(db, LoginEvent, LoginEvent.created_at >= since, LoginEvent.role == UserRole.SELLER),
        }
    return result
