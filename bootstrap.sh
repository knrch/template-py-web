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

# Initialize hooks
if command -v lefthook >/dev/null; then
    lefthook install
fi

# Bootstrap deps
if command -v mise >/dev/null; then
    mise install
fi

(cd backend && uv sync)
(cd frontend && pnpm install)

cat <<EOF

Bootstrap complete for project: $NAME

Next steps:
  1. Edit REQUIREMENTS.md
  2. cp .env.example .env  (and fill in values)
  3. Run 'just docker-up' and confirm http://localhost:8000/health works
  4. gh repo create knrch/$NAME --source=. --private --push
  5. Open this directory in Cursor and reference prompts/01-requirements-review.md
EOF
