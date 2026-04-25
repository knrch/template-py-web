"""Application settings via pydantic-settings.

Required vars without defaults will crash on import — by design.
"""
from __future__ import annotations

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    env: str = "dev"
    log_level: str = "INFO"
    database_url: str
    sentry_dsn: str | None = None

    # Generic deploy metadata — populated from platform-specific env in deploy
    # scripts (e.g., RAILWAY_GIT_COMMIT_SHA → GIT_SHA). App code reads only
    # the generic name, keeping the app cloud-agnostic.
    git_sha: str = "dev"

    # S3-compatible storage (optional)
    s3_endpoint: str | None = None
    s3_access_key: str | None = None
    s3_secret_key: str | None = None
    s3_bucket: str | None = None


@lru_cache
def get_settings() -> Settings:
    """Cached singleton. FastAPI deps and Alembic env both call this."""
    return Settings()  # type: ignore[call-arg]
