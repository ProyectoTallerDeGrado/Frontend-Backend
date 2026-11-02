"""Configuracion de la aplicacion, leida del entorno."""

from functools import lru_cache

from pydantic import model_validator
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

    # Autenticacion (JWT firmado con HS256). El secreto NO tiene valor por
    # defecto: debe venir del entorno.
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    # Origenes permitidos para CORS (la web en desarrollo corre en :3000).
    cors_origins: list[str] = ["http://localhost:3000"]

    # Zona horaria de negocio (agenda de mentorias) y etapa minima para agendar.
    app_timezone: str = "America/La_Paz"
    booking_min_stage_order: int = 2

    # Limite de intentos de login fallidos por (ip, correo).
    login_max_attempts: int = 5
    login_window_seconds: int = 900

    # IA local (Ollama). Si no responde, el asistente devuelve 503.
    ollama_base_url: str = "http://localhost:11434"
    ollama_embed_model: str = "nomic-embed-text"
    ollama_chat_model: str = "llama3.2"
    ollama_timeout_seconds: float = 60.0
    # Calibrado con nomic-embed-text: lo relevante sale entre 0.69 y 0.79 y lo que no
    # tiene relacion llega a 0.60; con 0.55 se colaban fuentes falsas. Ajustable por entorno.
    ai_min_similarity: float = 0.65
    ai_top_k: int = 4

    # Carga de archivos (modulo documents).
    upload_dir: str = "uploads"
    max_upload_mb: int = 10

    @property
    def is_production(self) -> bool:
        return self.environment.lower() == "production"

    @model_validator(mode="after")
    def _check_secrets(self) -> "Settings":
        """No se arranca con un secreto debil o de ejemplo, en ningun entorno."""
        if len(self.jwt_secret) < 32 or self.jwt_secret.startswith("cambia-este"):
            raise ValueError(
                "JWT_SECRET debe tener al menos 32 caracteres y no ser el de ejemplo. "
                'Genera uno: python -c "import secrets; print(secrets.token_urlsafe(48))"'
            )
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]  # los campos sin default vienen del entorno
