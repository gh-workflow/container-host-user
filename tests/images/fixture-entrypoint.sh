#!/bin/sh
set -eu

# Minimal original entrypoint used by hook/callback integration tests.
# By default it forwards to the requested command after the hook has had a
# chance to switch users.
#
# In print-args mode it reports the final uid/gid and each received argument.
# This is used to verify exact argv pass-through for hook-style integrations.

FIXTURE_MODE="${FIXTURE_MODE:-exec}"

if [ "${FIXTURE_MODE}" = "print-args" ]; then
  printf 'uid=%s\ngid=%s\nargc=%s\n' "$(id -u)" "$(id -g)" "$#"
  index=1
  for arg in "$@"; do
    printf 'arg%s=<%s>\n' "${index}" "${arg}"
    index=$((index + 1))
  done
  exit 0
fi

exec "$@"
