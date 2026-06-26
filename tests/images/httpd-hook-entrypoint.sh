#!/bin/sh
set -eu

# Test-only hook for the official httpd image. It applies
# container-host-user once and then returns to a fixture-local foreground launcher.

HTTPD_RUNTIME_UID="${HTTPD_UID:-}"
HTTPD_RUNTIME_GID="${HTTPD_GID:-}"
HTTPD_RUNTIME_USER="${HTTPD_USER:-httpdhost}"
HTTPD_RUNTIME_HOME="${HTTPD_HOME:-/home/${HTTPD_RUNTIME_USER}}"

if [ "$(id -u)" -eq 0 ] \
  && [ -n "${HTTPD_RUNTIME_UID}" ] \
  && [ -n "${HTTPD_RUNTIME_GID}" ] \
  && [ "${CHU_USER_SWITCHED:-0}" != "1" ]; then
  export CHU_UID="${HTTPD_RUNTIME_UID}"
  export CHU_GID="${HTTPD_RUNTIME_GID}"
  export CHU_USER="${HTTPD_RUNTIME_USER}"
  export CHU_HOME="${HTTPD_RUNTIME_HOME}"
  exec /usr/local/bin/container-host-user /httpd-foreground.sh "$@"
fi

exec /httpd-foreground.sh "$@"
