#!/bin/sh
set -eu

# Minimal original entrypoint used by hook/callback integration tests.
# It simply forwards to the requested command after the hook has had a chance
# to switch users.

exec "$@"
