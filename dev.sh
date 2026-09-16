#!/usr/bin/env bash
# Local preview with the same env vars Vercel uses. Copy local.env.example to local.env first.
set -euo pipefail
cd "$(dirname "$0")"
if [ -f local.env ]; then set -a; . ./local.env; set +a; fi
exec hugo server -D --port 1313 --bind 127.0.0.1 "$@"
