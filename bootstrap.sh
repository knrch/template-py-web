#!/usr/bin/env bash
# Rewrite template placeholders for a new project.
# Usage: ./bootstrap.sh <project-name>
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <project-name>" >&2
    exit 1
fi

NAME="$1"

# Replace <PROJECT_NAME> placeholders
find . -type f \( -name '*.md' -o -name '*.toml' -o -name '*.json' -o -name '*.yml' -o -name '*.yaml' \) \
    -not -path './.git/*' \
    -not -path './node_modules/*' \
    -not -path './.venv/*' \
    -exec sed -i.bak "s/<PROJECT_NAME>/$NAME/g" {} \;
find . -name '*.bak' -delete

# Initialize git if not already
if [[ ! -d .git ]]; then
    git init -b main
fi

# Bootstrap deps
if command -v mise >/dev/null; then
    mise install
fi

(cd backend && uv sync)
(cd frontend && pnpm install)

# Install pre-commit hooks (lefthook if available, else core.hooksPath)
./scripts/install-hooks.sh || true

cat <<EOF

Bootstrap complete for project: $NAME

Resolve digest placeholders before the first \`just docker-build\`:

  for img in python:3.14-slim node:24-alpine nginx:alpine caddy:2-alpine postgres:16-alpine ghcr.io/astral-sh/uv:0.11.8; do
    docker pull "\$img"
    docker inspect --format='{{index .RepoDigests 0}}' "\$img"
  done

Then substitute each PIN_ME_AT_BOOTSTRAP literal in:
  - backend/Dockerfile
  - frontend/Dockerfile
  - proxy/Dockerfile
  - docker-compose.yml
  - scripts/audit-all.sh   (RUNTIME_IMAGES + UV_IMAGE)

All locations must agree.

Next steps:
  1. Edit REQUIREMENTS.md
  2. cp .env.example .env  (and fill in values)
  3. just hooks-install     (verify audit tools are on PATH)
  4. just docker-up         and confirm http://localhost:8000/health works
  5. gh repo create knrch/$NAME --source=. --private --push
  6. Open this directory in Cursor and reference prompts/01-requirements-review.md
EOF
