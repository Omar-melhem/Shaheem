#!/usr/bin/env bash
# SHAHM DEMO (Task 37) — removes the debug demonstration mode.
#   bash tool/demo/remove_demo.sh --dry-run   # checks and plan, no change
#   bash tool/demo/remove_demo.sh --apply     # remove + gen-l10n + analyze + test
# Never runs git. See tool/demo/README.md.
set -euo pipefail
cd "$(dirname "$0")/../.."
exec dart tool/demo/remove_demo.dart "$@"
