"""Health endpoint smoke test (no DB needed for shape check)."""
from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_shape(client: AsyncClient) -> None:
    """Health returns expected JSON shape regardless of DB state."""
    r = await client.get("/health")
    assert r.status_code in (200, 503)
    body = r.json()
    assert "status" in body
    assert "version" in body
    assert "checks" in body
    assert "db" in body["checks"]
