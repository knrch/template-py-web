"""FastAPI application entrypoint."""
from __future__ import annotations

from contextlib import asynccontextmanager
from typing import AsyncIterator

import sentry_sdk
from fastapi import FastAPI
from sentry_sdk.integrations.fastapi import FastApiIntegration

from app.config import get_settings
from app.health import router as health_router
from app.logging import configure_logging, get_logger

log = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    configure_logging(level=settings.log_level)
    if settings.sentry_dsn:
        sentry_sdk.init(
            dsn=settings.sentry_dsn,
            integrations=[FastApiIntegration()],
            traces_sample_rate=0.1,
            release=settings.git_sha,
        )
    log.info("app_startup", env=settings.env, git_sha=settings.git_sha)
    yield
    log.info("app_shutdown")


app = FastAPI(
    title="<PROJECT_NAME>",
    lifespan=lifespan,
)

app.include_router(health_router)
