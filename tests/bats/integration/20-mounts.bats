#!/usr/bin/env bats

# Bind-mount ownership behavior across supported base images.

load ../helpers/common.bash

@test "writes bind-mounted files with the requested ownership" {
  local image
  local host_dir

  host_dir="$(mktemp -d)"
  trap 'cleanup_dir "${host_dir}"' EXIT
  prepare_bind_mount_dir "${host_dir}"

  for image in "${TEST_IMAGE_TAGS[@]}"; do
    run docker run --rm \
      -e CHU_UID=1234 \
      -e CHU_GID=2345 \
      -e CHU_USER=hostbind \
      -e CHU_HOME=/home/hostbind \
      -v "${host_dir}:/workspace" \
      "${image}" \
      sh -lc 'printf "ok\n" >/workspace/output.txt && stat -c "%u:%g" /workspace/output.txt'
    [ "$status" -eq 0 ]
    assert_output_eq "1234:2345" "${output}" "${image}: bind mount file owner inside container mismatch"

    run docker run --rm -v "${host_dir}:/workspace" alpine:3.22 \
      sh -lc 'rm -f /workspace/output.txt'
    [ "$status" -eq 0 ]
  done
}
