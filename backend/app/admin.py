"""Admin routes - request za kupitisha/kukataa matangazo ya nyumba,
na analytics ya dashboard (akaunti mpya na logins kwa muda mbalimbali).

Router hii yote inalindwa na `ensure_admin` - mtumiaji lazima awe
ameautheticate NA awe `is_admin=True`.
"""
from collections import defaultdict
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from .auth import ensure_admin
from .database import get_db
from .models import LoginEvent, Notification, Property, PropertyStatus, User, UserRole
from .schemas import AnalyticsPoint, AnalyticsSummary, PropertyResponse

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
