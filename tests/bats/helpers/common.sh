#!/usr/bin/env bash

# Shared helpers for bats-based integration tests.

repo_root=$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
readonly repo_root

# Image tags produced by setup_suite.sh.
readonly -a TEST_IMAGE_TAGS=(
  "container-host-user-test:alpine"
  "container-host-user-test:debian"
  "container-host-user-test:fedora"
  "container-host-user-test:ubuntu"
)

# Companion hook/callback fixture images for the same distro matrix.
readonly -a TEST_HOOK_IMAGE_TAGS=(
  "container-host-user-test:alpine-hook"
  "container-host-user-test:debian-hook"
  "container-host-user-test:fedora-hook"
  "container-host-user-test:ubuntu-hook"
)

# Fixture image that intentionally omits gosu and su-exec.
readonly TEST_NO_BACKEND_IMAGE="container-host-user-test:no-backend"

# Compare exact strings and print a readable mismatch.
assert_output_eq() {
  local expected="$1"
  local actual="$2"
  local message="${3:-values differ}"

  if [ "${expected}" != "${actual}" ]; then
    echo "${message}" >&2
    echo "expected: ${expected}" >&2
    echo "actual:   ${actual}" >&2
    return 1
  fi
}

# Require that an output blob contains a substring.
assert_output_contains() {
  local needle="$1"
  local haystack="$2"

  if [[ "${haystack}" != *"${needle}"* ]]; then
    echo "expected output to contain: ${needle}" >&2
    echo "${haystack}" >&2
    return 1
  fi
}

# Best-effort cleanup for temporary bind-mount fixtures.
cleanup_dir() {
  local dir="$1"

  if [ -n "${dir}" ] && [ -d "${dir}" ]; then
    chmod -R u+w "${dir}" >/dev/null 2>&1 || true
    rm -rf "${dir}" >/dev/null 2>&1 || true
  fi
}

# Prepare a host directory with deterministic ownership for mount tests.
prepare_bind_mount_dir() {
  local dir="$1"

  chmod 0777 "${dir}"
  docker run --rm -v "${dir}:/workspace" alpine:3.22 \
    sh -lc 'chown 1234:2345 /workspace && chmod 0777 /workspace'
}
