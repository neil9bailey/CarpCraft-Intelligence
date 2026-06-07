from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = Field(default="CarpCraft Intelligence", alias="APP_NAME")
    app_env: str = Field(default="local", alias="APP_ENV")
    api_version: str = Field(default="0.1.0", alias="API_VERSION")
    database_url: str | None = Field(default=None, alias="DATABASE_URL")
    auth_mode: str = Field(default="local", alias="AUTH_MODE")
    auth_required: bool = Field(default=False, alias="AUTH_REQUIRED")
    local_dev_user_id: str = Field(default="local-dev-user", alias="LOCAL_DEV_USER_ID")
    entra_tenant_id: str = Field(default="67f8be6c-07da-4a7c-bb0a-d6bcb38cd6da", alias="ENTRA_TENANT_ID")
    entra_audience: str | None = Field(default=None, alias="ENTRA_AUDIENCE")
    entra_audiences: str | None = Field(default=None, alias="ENTRA_AUDIENCES")
    entra_issuer: str | None = Field(default=None, alias="ENTRA_ISSUER")
    entra_jwks_uri: str | None = Field(default=None, alias="ENTRA_JWKS_URI")
    entra_default_tenant: str = Field(default="diiac.io", alias="ENTRA_DEFAULT_TENANT")
    default_privacy_level: str = Field(default="private", alias="DEFAULT_PRIVACY_LEVEL")
    open_meteo_base_url: str = Field(default="https://api.open-meteo.com", alias="OPEN_METEO_BASE_URL")
    weather_primary_provider: str = Field(default="open_meteo", alias="WEATHER_PRIMARY_PROVIDER")
    weather_secondary_provider: str = Field(default="met_office", alias="WEATHER_SECONDARY_PROVIDER")
    met_office_api_key: str | None = Field(default=None, alias="MET_OFFICE_API_KEY")
    met_office_base_url: str = Field(default="https://data.hub.api.metoffice.gov.uk", alias="MET_OFFICE_BASE_URL")
    google_maps_api_key: str | None = Field(default=None, alias="GOOGLE_MAPS_API_KEY")
    google_places_enabled: bool = Field(default=False, alias="GOOGLE_PLACES_ENABLED")
    google_places_api_key: str | None = Field(default=None, alias="GOOGLE_PLACES_API_KEY")
    google_places_base_url: str = Field(default="https://places.googleapis.com", alias="GOOGLE_PLACES_BASE_URL")
    ai_explanations_enabled: bool = Field(default=False, alias="AI_EXPLANATIONS_ENABLED")
    openai_api_key: str | None = Field(default=None, alias="OPENAI_API_KEY")
    openai_model: str | None = Field(default=None, alias="OPENAI_MODEL")
    anglingai_api_key: str | None = Field(default=None, alias="ANGLINGAI_API_KEY")
    anglingai_base_url: str = Field(default="https://anglingai.co.uk/api/v1", alias="ANGLINGAI_BASE_URL")

    model_config = SettingsConfigDict(env_file=(".env", "../.env"), extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
