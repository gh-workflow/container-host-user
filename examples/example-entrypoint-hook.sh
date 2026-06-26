#!/bin/sh
set -eu

EXAMPLE_RUNTIME_UID="${EXAMPLE_UID:-}"
EXAMPLE_RUNTIME_GID="${EXAMPLE_GID:-}"
EXAMPLE_RUNTIME_USER="${EXAMPLE_USER:-megalinter}"
EXAMPLE_RUNTIME_HOME="${HOME:-/home/${EXAMPLE_RUNTIME_USER}}"

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

exec /entrypoint.sh "$@"
