#!/usr/bin/env bats

# Runtime-user provisioning behavior across supported base images.

load helpers/common.sh

@test "no-op without CHU_UID and CHU_GID" {
  local image

  for image in "${TEST_IMAGE_TAGS[@]}"; do
    run docker run --rm "${image}" sh -lc 'printf "%s:%s\n" "$(id -u)" "$(id -g)"'
    [ "$status" -eq 0 ]
    assert_output_eq "0:0" "$output" "${image}: script should no-op when CHU_UID and CHU_GID are unset"
  done
}

@test "creates runtime user and home" {
  local image
  local -a lines

  for image in "${TEST_IMAGE_TAGS[@]}"; do
    run docker run --rm \
      -e CHU_UID=1234 \
      -e CHU_GID=2345 \
      -e CHU_USER=demo \
      -e CHU_HOME=/home/demo \
      "${image}" \
      sh -lc 'printf "%s\n%s\n%s\n%s\n" "$(id -u)" "$(id -g)" "$(id -un)" "$HOME"'
    [ "$status" -eq 0 ]
    mapfile -t lines <<<"${output}"
    assert_output_eq "1234" "${lines[0]}" "${image}: uid mismatch"
    assert_output_eq "2345" "${lines[1]}" "${image}: gid mismatch"
    assert_output_eq "demo" "${lines[2]}" "${image}: user mismatch"
    assert_output_eq "/home/demo" "${lines[3]}" "${image}: home mismatch"
  done
}

@test "reuses existing uid instead of replacing it" {
  local image
  local tail_line
  local user group uid gid home

  for image in "${TEST_IMAGE_TAGS[@]}"; do
    run docker run --rm --entrypoint sh \
      -e CHU_UID=1000 \
      -e CHU_GID=1000 \
      -e CHU_USER=hostuser \
      -e CHU_HOME=/home/hostuser \
      "${image}" \
      -lc "
        set -eu
        if command -v groupadd >/dev/null 2>&1; then
          getent group 1000 >/dev/null 2>&1 || groupadd -g 1000 seededuser
        else
          getent group 1000 >/dev/null 2>&1 || addgroup -g 1000 seededuser >/dev/null
        fi
        if command -v useradd >/dev/null 2>&1; then
          getent passwd 1000 >/dev/null 2>&1 || useradd -m -u 1000 -g 1000 -d /home/seededuser -s /bin/sh seededuser
        else
          getent passwd 1000 >/dev/null 2>&1 || adduser -D -H -u 1000 -G seededuser -h /home/seededuser -s /bin/sh seededuser >/dev/null
        fi
        /usr/local/bin/container-host-user sh -lc 'printf \"%s:%s:%s:%s:%s\n\" \"\$(id -un)\" \"\$(id -gn)\" \"\$(id -u)\" \"\$(id -g)\" \"\$HOME\"'
      "
    [ "$status" -eq 0 ]
    tail_line="$(printf '%s\n' "${output}" | tail -n 1)"
    IFS=':' read -r user group uid gid home <<<"${tail_line}"
    assert_output_eq "seededuser" "${user}" "${image}: existing uid should be reused"
    assert_output_eq "seededuser" "${group}" "${image}: existing primary group should be reused"
    assert_output_eq "1000" "${uid}" "${image}: reused uid mismatch"
    assert_output_eq "1000" "${gid}" "${image}: reused gid mismatch"
    assert_output_eq "/home/seededuser" "${home}" "${image}: reused home mismatch"
  done
}

@test "reowns an existing home directory" {
  local image
  local tail_line
  local uid gid home home_uid home_gid

  for image in "${TEST_IMAGE_TAGS[@]}"; do
    run docker run --rm --entrypoint sh \
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
    [ "$status" -eq 0 ]
    tail_line="$(printf '%s\n' "${output}" | tail -n 1)"
    IFS=':' read -r uid gid home home_uid home_gid <<<"${tail_line}"
    assert_output_eq "2234" "${uid}" "${image}: home reown uid mismatch"
    assert_output_eq "3234" "${gid}" "${image}: home reown gid mismatch"
    assert_output_eq "/home/demo" "${home}" "${image}: home path mismatch"
    assert_output_eq "2234" "${home_uid}" "${image}: home owner uid mismatch"
    assert_output_eq "3234" "${home_gid}" "${image}: home owner gid mismatch"
  done
}
