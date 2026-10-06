#!/bin/bash
# Runs Niram's unit tests. Fails when they fail or do not build.
set -euo pipefail
cd "$(dirname "$0")"
swift test 2>&1 | grep -E "error:|warning:|✘|passed|failed|Executed" || true
swift test > /dev/null 2>&1
