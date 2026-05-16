#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_BIN="$ROOT_DIR/bin/wpctl"

mkdir -p "$ROOT_DIR/bin"
cd "$ROOT_DIR"
go build -o "$OUT_BIN" ./cmd/wpctl

echo "Built $OUT_BIN"
