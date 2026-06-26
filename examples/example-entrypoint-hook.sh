#!/bin/sh
set -eu

# Example entrypoint hook for an image that already has its own /entrypoint.sh.
# This translates project-specific runtime-user variables into CHU_* variables
# and then hands control to container-host-user once.

# Upstream image inputs that determine the target runtime account.
EXAMPLE_RUNTIME_UID="${EXAMPLE_UID:-}"
EXAMPLE_RUNTIME_GID="${EXAMPLE_GID:-}"
EXAMPLE_RUNTIME_USER="${EXAMPLE_USER:-megalinter}"
EXAMPLE_RUNTIME_HOME="${HOME:-/home/${EXAMPLE_RUNTIME_USER}}"

# Switch exactly once, then allow the original entrypoint to continue.
if [ "$(id -u)" -eq 0 ] \
  && [ -n "${EXAMPLE_RUNTIME_UID}" ] \
  && [ -n "${EXAMPLE_RUNTIME_GID}" ] \
  && [ "${CHU_USER_SWITCHED:-0}" != "1" ]; then
  export CHU_UID="${EXAMPLE_RUNTIME_UID}"
  export CHU_GID="${EXAMPLE_RUNTIME_GID}"
  export CHU_USER="${EXAMPLE_RUNTIME_USER}"
  export CHU_HOME="${EXAMPLE_RUNTIME_HOME}"
  exec /usr/local/bin/container-host-user /entrypoint.sh "$@"
fi

# Either already switched or not configured: continue with the original entrypoint.
exec /entrypoint.sh "$@"
