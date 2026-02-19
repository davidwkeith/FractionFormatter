#!/usr/bin/env bash
set -euo pipefail

if ! command -v swift-format >/dev/null 2>&1; then
  echo "swift-format not found"
  exit 1
fi

swift-format lint -r Sources Tests
