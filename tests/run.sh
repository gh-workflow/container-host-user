#!/bin/sh
set -eu

# User-facing test runner.
# Run this script to execute the full bats suite, including setup_suite.

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

exec bats --recursive "${repo_root}/tests/bats"
