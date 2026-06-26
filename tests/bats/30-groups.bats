#!/usr/bin/env bats

# Supplemental-group behavior across supported base images.

load helpers/common.sh

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
