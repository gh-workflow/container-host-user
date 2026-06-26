#!/usr/bin/env bats

# Supplemental-group behavior across supported base images.

load helpers/common.bash

@test "adds the runtime user to supplemental gids" {
  local image
  local -a lines

  for image in "${TEST_IMAGE_TAGS[@]}"; do
    run docker run --rm --entrypoint sh \
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
    [ "$status" -eq 0 ]
    mapfile -t lines <<<"${output}"
    assert_output_contains "2999" " ${lines[0]} "
    assert_output_contains "3000" " ${lines[0]} "
    assert_output_eq "1234:2345" "${lines[1]}" "${image}: supplemental group should not replace primary group"
  done
}

@test "reuses an existing group for a requested supplemental gid" {
  local image
  local -a lines

  for image in "${TEST_IMAGE_TAGS[@]}"; do
    run docker run --rm --entrypoint sh \
      -e CHU_UID=1234 \
      -e CHU_GID=2345 \
      -e CHU_USER=demo \
      -e CHU_HOME=/home/demo \
      -e CHU_EXTRA_GIDS=2999 \
      "${image}" \
      -lc "
        set -eu
        if command -v groupadd >/dev/null 2>&1; then
          getent group 2999 >/dev/null 2>&1 || groupadd -g 2999 sharedgid
        else
          getent group 2999 >/dev/null 2>&1 || addgroup -g 2999 sharedgid >/dev/null
        fi
        mkdir -p /shared
        chown 0:2999 /shared
        chmod 0770 /shared
        /usr/local/bin/container-host-user sh -lc 'printf \"%s\n%s\n\" \"\$(id -nG)\" \"\$(touch /shared/probe && stat -c %u:%g /shared/probe)\"'
      "
    [ "$status" -eq 0 ]
    mapfile -t lines <<<"${output}"
    assert_output_contains "sharedgid" " ${lines[0]} "
    assert_output_eq "1234:2345" "${lines[1]}" "${image}: existing supplemental group should preserve primary uid/gid"
  done
}

@test "accepts duplicate gids and mixed separators in CHU_EXTRA_GIDS" {
  local image
  local -a lines

  for image in "${TEST_IMAGE_TAGS[@]}"; do
    run docker run --rm --entrypoint sh \
      -e CHU_UID=1234 \
      -e CHU_GID=2345 \
      -e CHU_USER=demo \
      -e CHU_HOME=/home/demo \
      -e CHU_EXTRA_GIDS='2999, 3000 2999' \
      "${image}" \
      -lc "
        set -eu
        mkdir -p /shared-a /shared-b
        chown 0:2999 /shared-a
        chown 0:3000 /shared-b
        chmod 0770 /shared-a /shared-b
        /usr/local/bin/container-host-user sh -lc 'printf \"%s\n\" \"\$(id -G)\"; touch /shared-a/a /shared-b/b'
      "
    [ "$status" -eq 0 ]
    mapfile -t lines <<<"${output}"
    assert_output_contains "2999" " ${lines[0]} "
    assert_output_contains "3000" " ${lines[0]} "
  done
}
