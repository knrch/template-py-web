# syntax=docker/dockerfile:1.7
# Resolve real digests at bootstrap (mirror into docker-compose.yml + scripts/audit-all.sh):
#   docker pull python:3.14-slim
#   docker inspect --format='{{index .RepoDigests 0}}' python:3.14-slim
#   docker pull ghcr.io/astral-sh/uv:0.11.8
#   docker inspect --format='{{index .RepoDigests 0}}' ghcr.io/astral-sh/uv:0.11.8

FROM python:3.14-slim@sha256:PIN_ME_AT_BOOTSTRAP AS builder
WORKDIR /app
ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PROJECT_ENVIRONMENT=/app/.venv \
    PIP_DISABLE_PIP_VERSION_CHECK=1

COPY --from=ghcr.io/astral-sh/uv:0.11.8@sha256:PIN_ME_AT_BOOTSTRAP /uv /uvx /usr/local/bin/

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project --no-dev

COPY . .
RUN uv sync --frozen --no-dev

FROM python:3.14-slim@sha256:PIN_ME_AT_BOOTSTRAP
WORKDIR /app
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1
RUN useradd --create-home --uid 1000 app
COPY --from=builder --chown=app:app /app /app
USER app
EXPOSE 8000
ENTRYPOINT ["/app/.venv/bin/python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
