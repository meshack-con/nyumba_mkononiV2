from datetime import datetime
from pydantic import BaseModel, ConfigDict, EmailStr, Field, model_validator
from .models import PropertyMode, PropertyStatus, PropertyType, UserRole
class UserCreate(BaseModel):
    jina_kamili: str = Field(min_length=2, max_length=150)
    namba_ya_simu: str = Field(min_length=7, max_length=30)
    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=8, max_length=128)
    role: UserRole
    email: EmailStr | None = None
    eneo: str | None = Field(default=None, max_length=150)
    @model_validator(mode="after")
    def seller_fields_required(self):
        if self.role == UserRole.SELLER and (self.email is None or not self.eneo):
            raise ValueError("Seller lazima awe na email na eneo")
        return self
class LoginRequest(BaseModel):
    username: str
    password: str
class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    jina_kamili: str
    namba_ya_simu: str
    username: str
    email: EmailStr | None
    role: UserRole
    is_admin: bool
    eneo: str | None
    profile_picha_url: str | None = None
    created_at: datetime
class UserUpdate(BaseModel):
    """Taarifa binafsi zinazoruhusiwa kuhaririwa na mtumiaji mwenyewe."""
    jina_kamili: str | None = Field(default=None, min_length=2, max_length=150)
    namba_ya_simu: str | None = Field(default=None, min_length=7, max_length=30)
    email: EmailStr | None = None
    eneo: str | None = Field(default=None, max_length=150)

class FeedbackCreate(BaseModel):
    message: str = Field(min_length=1, max_length=1000)

    @model_validator(mode="after")
    def message_not_blank(self):
        self.message = self.message.strip()
        if not self.message:
            raise ValueError("Feedback haiwezi kuwa tupu")
        return self

class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
class PropertyResponse(BaseModel):
    """Response kamili yenye verification_doc_url.
    TUMIA HII TU kwa endpoints zenye auth ambapo mwenye tangazo (seller)
    anaona taarifa zake mwenyewe (create_property, /properties/mine).
    USITUMIE kwa endpoints za public - tumia PublicPropertyResponse.
    """
    model_config = ConfigDict(from_attributes=True)
    id: int
    owner_id: int
    jina: str
    aina: PropertyType
    mode: PropertyMode
    price: int
    location_label: str
    latitude: float
    longitude: float
    has_wifi: bool
    car_parking: bool
    indoor_toilet: bool
    has_electricity: bool
    water_inside: bool
    water_nearby: bool
    furnished: bool
    swimming_pool: bool
    view_count: int
    description: str
    photo_urls: list[str]
    verification_doc_url: str | None
    status: PropertyStatus
    created_at: datetime
    expires_at: datetime | None
    favorites_count: int = 0
    unread_messages_count: int = 0
class PropertyUpdate(BaseModel):
    """Sehemu zinazoruhusiwa kuhaririwa na mwenye tangazo (seller) baada
    ya kuweka tangazo lake. Picha na hati ya uthibitisho HAZIBADILISHWI
    hapa - ni za kudumu tangu kuunda tangazo. Field zote ni hiari (Optional)
    ili PATCH iweze kutuma sehemu tu zilizobadilika."""
    jina: str | None = Field(default=None, min_length=2, max_length=180)
    aina: PropertyType | None = None
    mode: PropertyMode | None = None
    price: int | None = Field(default=None, ge=0)
    location_label: str | None = Field(default=None, min_length=1, max_length=180)
    latitude: float | None = None
    longitude: float | None = None
    has_wifi: bool | None = None
    car_parking: bool | None = None
    indoor_toilet: bool | None = None
    has_electricity: bool | None = None
    water_inside: bool | None = None
    water_nearby: bool | None = None
    furnished: bool | None = None
    swimming_pool: bool | None = None
    description: str | None = Field(default=None, min_length=1)
class PublicPropertyResponse(BaseModel):
    """Response ya public - HAINA verification_doc_url.
    TUMIA HII kwa endpoints zozote zinazoweza kufikiwa na buyer/umma
    (GET /properties, GET /properties/{id}, FavoriteResponse.property).
    """
    model_config = ConfigDict(from_attributes=True)
    id: int
    owner_id: int
    jina: str
    aina: PropertyType
    mode: PropertyMode
    price: int
    location_label: str
    latitude: float
    longitude: float
    has_wifi: bool
    car_parking: bool
    indoor_toilet: bool
    has_electricity: bool
    water_inside: bool
    water_nearby: bool
    furnished: bool
    swimming_pool: bool
    view_count: int
    description: str
    photo_urls: list[str]
    status: PropertyStatus
    created_at: datetime
    expires_at: datetime | None
class FavoriteResponse(BaseModel):
    id: int
    property_id: int
    created_at: datetime
    property: PublicPropertyResponse
class PropertyWithOwnerResponse(PublicPropertyResponse):
    owner_jina: str
    owner_simu: str
    owner_email: str | None = None
class AnalyticsPoint(BaseModel):
    period: str
    buyer: int = 0
    seller: int = 0
    total: int = 0
class AnalyticsSummary(BaseModel):
    total_buyers: int
    total_sellers: int
    total_users: int
    pending_properties: int
    registrations_today: int
    registrations_this_week: int
    registrations_this_month: int
    registrations_this_year: int
    logins_today: int
    logins_this_week: int
    logins_this_month: int
    logins_this_year: int
class MessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=2000)
    receiver_id: int | None = None
class MessageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    property_id: int
    sender_id: int
    receiver_id: int
    content: str
    created_at: datetime
    read_at: datetime | None
class ConversationResponse(BaseModel):
    """Kikundi cha mazungumzo (thread) kati ya mtumiaji na mtu mwingine
    kuhusu tangazo maalum - kinatumika kwenye 'inbox' ya mpangishaji/mnunuzi
    kuonyesha ujumbe wa hivi karibuni na idadi ya ujumbe usiosomwa."""
    property_id: int
    property_name: str
    other_user_id: int
    other_user_name: str
    last_message: str
    last_message_at: datetime
    last_sender_id: int
    unread_count: int
class NotificationResponse(BaseModel):
    """Arifa moja iliyoungalishwa - inaweza kutoka kwa platform yenyewe
    (type='platform') au kuwa muhtasari wa mazungumzo na mmiliki wa
    nyumba / mnunuzi (type='owner')."""
    id: str
    type: str
    title: str
    body: str
    created_at: datetime
    read: bool
    property_id: int | None = None
    property_name: str | None = None
    other_user_id: int | None = None


# --- Malipo ya ada ya kutangaza nyumba (ClickPesa) -----------------------

class PaymentInitiateRequest(BaseModel):
    """Namba ya simu itakayotumika kulipia ada ya TZS 5,000 (haihitajiki
    kama si lazima kwa aina ya malipo aliyochagua mtumiaji - lakini
    tunaitumia kwa mobile money ya Tanzania)."""
    phone_number: str = Field(min_length=7, max_length=20)


class PaymentInitiateResponse(BaseModel):
    tx_ref: str
    amount: int
    currency: str
    status: str
    # Mtandao wa simu ulioombwa kutuma USSD-PUSH, mfano "M-PESA",
    # "TIGO-PESA", "AIRTEL-MONEY" - hutumiwa na app kumwambia muuzaji
    # aangalie simu yake ya mtandao gani.
    channel: str | None = None


class PaymentStatusResponse(BaseModel):
    tx_ref: str
    status: str
    amount: int
    currency: str
    used: bool
