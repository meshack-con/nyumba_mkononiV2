from collections.abc import Generator

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker


class Settings(BaseSettings):
    database_url: str
    jwt_secret_key: str
    jwt_expire_minutes: int = 60
    cors_origins: str = "http://localhost:3000,http://localhost:8080"
    cloudinary_cloud_name: str = ""
    cloudinary_api_key: str = ""
    cloudinary_api_secret: str = ""

    # --- ClickPesa (malipo ya ada ya kutangaza nyumba - TZS 5,000) ------
    # Client ID na API Key zinapatikana kwenye ClickPesa Merchant
    # Dashboard (https://merchant.clickpesa.com) -> Settings ->
    # Developers -> (application yako) -> API Keys.
    clickpesa_client_id: str = ""
    clickpesa_api_key: str = ""
    # Weka hii TU kama umewasha "Checksum" kwenye Dashboard yako kwa
    # application hii (Settings -> Developers -> application -> Checksum).
    # Ikiwa umewasha, thamani hii lazima IFANANE KABISA na ile
    # iliyowekwa kwenye Dashboard - vinginevyo maombi yako yatakataliwa
    # na webhook haitathibitika. Ukibadilisha mpangilio huu Dashboard-ni,
    # ni lazima uzalishe upya API tokens zako (ClickPesa wanavyoeleza).
    clickpesa_checksum_key: str = ""
    # ClickPesa haina "sandbox" - majaribio hufanyika dhidi ya production
    # halisi kwa kiasi kidogo cha pesa (soma:
    # https://docs.clickpesa.com/home/sandbox-and-testing-environment).
    clickpesa_base_url: str = "https://api.clickpesa.com/third-parties"
    # Ada ya kutangaza nyumba moja (seller analipa hii kabla tangazo halijapokelewa).
    property_listing_fee: int = 5000
    property_listing_currency: str = "TZS"

    # --- Msaidizi wa AI (Groq) - key hii inakaa upande wa server PEKEE,
    # haiwahi kutumwa kwenda kwenye Flutter web build, hivyo haionekani
    # kwenye browser ya mtumiaji. ------------------------------------
    groq_api_key: str = ""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @field_validator("*", mode="before")
    @classmethod
    def _strip_whitespace(cls, value):
        # Env vars zilizowekwa kwenye Render (au popote) mara nyingi
        # zinakuja na "\n" au nafasi mwishoni pale zinapo-copy-paste -
        # HTTP haikubali "\n" kwenye header value, hivyo httpx inatupa
        # "Illegal header value". Hii inasafisha thamani ZOTE za string
        # mara moja badala ya kila mahali kwenye msimbo.
        if isinstance(value, str):
            return value.strip()
        return value


settings = Settings()
engine = create_engine(settings.database_url, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


class Base(DeclarativeBase):
    pass


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
