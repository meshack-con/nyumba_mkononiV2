from collections.abc import Generator

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

    # --- Flutterwave (malipo ya ada ya kutangaza nyumba - TZS 5,000) ----
    # Hizi ni "Test API keys" (v4 - OAuth2 client credentials), zinazopatikana
    # kwenye Flutterwave Dashboard -> Developers -> Test API keys.
    flutterwave_client_id: str = ""
    flutterwave_client_secret: str = ""
    flutterwave_encryption_key: str = ""
    # "verif-hash"/"flutterwave-signature" secret unayoiweka kwenye Flutterwave
    # Dashboard -> Webhooks, kwa ajili ya kuthibitisha kuwa webhook inatoka
    # kwa Flutterwave kweli (siyo mtu anayejifanya).
    flutterwave_webhook_secret_hash: str = ""
    # Sandbox (test keys) hutumia "developersandbox-api...", production
    # hutumia "api.flutterwave.cloud/f4b/production" - badilisha unapokwenda live.
    flutterwave_base_url: str = "https://developersandbox-api.flutterwave.com"
    flutterwave_idp_url: str = "https://idp.flutterwave.com/realms/flutterwave/protocol/openid-connect/token"
    # Ada ya kutangaza nyumba moja (seller analipa hii kabla tangazo halijapokelewa).
    property_listing_fee: int = 5000
    property_listing_currency: str = "TZS"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


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
