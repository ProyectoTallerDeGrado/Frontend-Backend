"""Configuracion de la aplicacion, leida del entorno."""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "EmprendeU API"
    environment: str = "development"
    api_v1_prefix: str = "/api/v1"

    # URL async de SQLAlchemy, p. ej.
    # postgresql+psycopg://emprendeu:emprendeu@localhost:5432/emprendeu
    database_url: str
    db_schema: str = "cieu"
    db_echo: bool = False
    db_pool_size: int = 5
    db_max_overflow: int = 10


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]  # los campos sin default vienen del entorno
