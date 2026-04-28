#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v make &>/dev/null; then
  sudo apt-get install -y make
fi

make -C "$SCRIPT_DIR" all
