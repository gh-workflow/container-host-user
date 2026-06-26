#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
dockerfile="${repo_root}/tests/images/Dockerfile"
project_tag="container-host-user-test"

images=(
  "alpine:3.22|${project_tag}:alpine"
  "debian:bookworm-slim|${project_tag}:debian"
  "ubuntu:24.04|${project_tag}:ubuntu"
)

cleanup() {
  local dir="${1:-}"
  if [ -n "${dir}" ] && [ -d "${dir}" ]; then
    chmod -R u+w "${dir}" >/dev/null 2>&1 || true
    rm -rf "${dir}" >/dev/null 2>&1 || true
  fi
}

run_capture() {
  local tmp
  tmp="$(mktemp)"
  if "$@" >"${tmp}" 2>&1; then
    RUN_STATUS=0
  else
    RUN_STATUS=$?
  fi
  RUN_OUTPUT="$(cat "${tmp}")"
  rm -f "${tmp}"
}

assert_status() {
  local expected="$1"
  if [ "${RUN_STATUS}" -ne "${expected}" ]; then
    printf 'expected exit status %s, got %s\n%s\n' "${expected}" "${RUN_STATUS}" "${RUN_OUTPUT}" >&2
    exit 1
  fi
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="${3:-values differ}"
  if [ "${expected}" != "${actual}" ]; then
    printf '%s\nexpected: %s\nactual:   %s\n' "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_contains() {
  local needle="$1"
  local haystack="$2"
  if [[ "${haystack}" != *"${needle}"* ]]; then
    printf 'expected output to contain: %s\n%s\n' "${needle}" "${haystack}" >&2
    exit 1
  fi
}

build_image() {
  local base_image="$1"
  local tag="$2"
  docker build \
    --build-arg "BASE_IMAGE=${base_image}" \
    -t "${tag}" \
    -f "${dockerfile}" \
    "${repo_root}" >/dev/null
}

test_noop_without_uid_gid() {
  local image="$1"
  run_capture docker run --rm "${image}" sh -lc 'printf "%s:%s\n" "$(id -u)" "$(id -g)"'
  assert_status 0
  assert_eq "0:0" "${RUN_OUTPUT}" "script should no-op when CHU_UID and CHU_GID are unset"
}

test_runtime_user_creation() {
  local image="$1"
  run_capture docker run --rm \
    -e CHU_UID=1234 \
    -e CHU_GID=2345 \
    -e CHU_USER=demo \
    -e CHU_HOME=/home/demo \
    "${image}" \
    sh -lc 'printf "%s\n%s\n%s\n%s\n" "$(id -u)" "$(id -g)" "$(id -un)" "$HOME"'
  assert_status 0
  mapfile -t lines <<<"${RUN_OUTPUT}"
  assert_eq "1234" "${lines[0]}" "uid mismatch"
  assert_eq "2345" "${lines[1]}" "gid mismatch"
  assert_eq "demo" "${lines[2]}" "user mismatch"
  assert_eq "/home/demo" "${lines[3]}" "home mismatch"
}

test_existing_uid_is_reused() {
  local image="$1"
  run_capture docker run --rm --entrypoint sh \
    -e CHU_UID=1000 \
    -e CHU_GID=1000 \
    -e CHU_USER=hostuser \
    -e CHU_HOME=/home/hostuser \
    "${image}" \
    -lc "
      set -eu
      if command -v groupadd >/dev/null 2>&1; then
        getent group 1000 >/dev/null 2>&1 || groupadd -g 1000 ubuntu
      else
        getent group 1000 >/dev/null 2>&1 || addgroup -g 1000 ubuntu >/dev/null
      fi
      if command -v useradd >/dev/null 2>&1; then
        getent passwd 1000 >/dev/null 2>&1 || useradd -m -u 1000 -g 1000 -d /home/ubuntu -s /bin/sh ubuntu
      else
        getent passwd 1000 >/dev/null 2>&1 || adduser -D -H -u 1000 -G ubuntu -h /home/ubuntu -s /bin/sh ubuntu >/dev/null
      fi
      /usr/local/bin/container-host-user sh -lc 'printf \"%s:%s:%s:%s:%s\n\" \"\$(id -un)\" \"\$(id -gn)\" \"\$(id -u)\" \"\$(id -g)\" \"\$HOME\"'
    "
  assert_status 0
  tail_line="$(printf '%s\n' "${RUN_OUTPUT}" | tail -n 1)"
  IFS=':' read -r user group uid gid home <<<"${tail_line}"
  assert_eq "ubuntu" "${user}" "existing uid should be reused"
  assert_eq "ubuntu" "${group}" "existing primary group should be reused"
  assert_eq "1000" "${uid}" "reused uid mismatch"
  assert_eq "1000" "${gid}" "reused gid mismatch"
  assert_eq "/home/ubuntu" "${home}" "reused home mismatch"
}

test_existing_home_reowned() {
  local image="$1"
  run_capture docker run --rm --entrypoint sh \
    -e CHU_UID=2234 \
    -e CHU_GID=3234 \
    -e CHU_USER=demo \
    -e CHU_HOME=/home/demo \
    "${image}" \
    -lc "
      set -eu
      mkdir -p /home/demo
      chown 0:0 /home/demo
      /usr/local/bin/container-host-user sh -lc 'printf \"%s:%s:%s:%s\n\" \"\$(id -u)\" \"\$(id -g)\" \"\$HOME\" \"\$(stat -c %u:%g /home/demo)\"'
    "
  assert_status 0
  tail_line="$(printf '%s\n' "${RUN_OUTPUT}" | tail -n 1)"
  IFS=':' read -r uid gid home home_uid home_gid <<<"${tail_line}"
  assert_eq "2234" "${uid}" "home reown uid mismatch"
  assert_eq "3234" "${gid}" "home reown gid mismatch"
  assert_eq "/home/demo" "${home}" "home path mismatch"
  assert_eq "2234" "${home_uid}" "home owner uid mismatch"
  assert_eq "3234" "${home_gid}" "home owner gid mismatch"
}

test_bind_mount_ownership() {
  local image="$1"
  local host_dir
  host_dir="$(mktemp -d)"
  chmod 0777 "${host_dir}"
  trap 'cleanup "${host_dir}"' RETURN
  run_capture docker run --rm -v "${host_dir}:/workspace" alpine:3.22 sh -lc 'chown 1234:2345 /workspace && chmod 0777 /workspace'
  assert_status 0
  run_capture docker run --rm \
    -e CHU_UID=1234 \
    -e CHU_GID=2345 \
    -e CHU_USER=hostbind \
    -e CHU_HOME=/home/hostbind \
    -v "${host_dir}:/workspace" \
    "${image}" \
    sh -lc 'printf "ok\n" >/workspace/output.txt && stat -c "%u:%g" /workspace/output.txt'
  assert_status 0
  assert_eq "1234:2345" "${RUN_OUTPUT}" "bind mount file owner inside container mismatch"
  run_capture docker run --rm -v "${host_dir}:/workspace" alpine:3.22 sh -lc 'test -f /workspace/output.txt && stat -c "%u:%g" /workspace/output.txt'
  assert_status 0
  assert_eq "1234:2345" "${RUN_OUTPUT}" "bind mount file owner across containers mismatch"
  trap - RETURN
  cleanup "${host_dir}"
}

test_extra_groups_grant_access() {
  local image="$1"
  run_capture docker run --rm --entrypoint sh \
    -e CHU_UID=1234 \
    -e CHU_GID=2345 \
    -e CHU_USER=demo \
    -e CHU_HOME=/home/demo \
    -e CHU_EXTRA_GIDS=2999,3000 \
    "${image}" \
    -lc "
      set -eu
      mkdir -p /shared
      chown 0:2999 /shared
      chmod 0770 /shared
      /usr/local/bin/container-host-user sh -lc 'printf \"%s\n\" \"\$(id -G)\"; touch /shared/probe; stat -c \"%u:%g\" /shared/probe'
    "
  assert_status 0
  mapfile -t lines <<<"${RUN_OUTPUT}"
  assert_contains "2999" " ${lines[0]} "
  assert_contains "3000" " ${lines[0]} "
  assert_eq "1234:2345" "${lines[1]}" "supplemental group should not replace primary group"
}

for image_def in "${images[@]}"; do
  IFS='|' read -r base_image tag <<<"${image_def}"
  printf 'building %s from %s\n' "${tag}" "${base_image}"
  build_image "${base_image}" "${tag}"

  printf 'testing %s\n' "${tag}"
  test_noop_without_uid_gid "${tag}"
  test_runtime_user_creation "${tag}"
  test_existing_uid_is_reused "${tag}"
  test_existing_home_reowned "${tag}"
  test_bind_mount_ownership "${tag}"
  test_extra_groups_grant_access "${tag}"
done

printf 'integration tests passed\n'
