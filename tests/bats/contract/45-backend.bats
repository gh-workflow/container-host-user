#!/usr/bin/env bats

# Approved privilege-drop backend requirements.

load ../helpers/common.sh

@test "fails clearly when neither gosu nor su-exec is installed" {
  run docker run --rm \
    -e CHU_UID=1234 \
    -e CHU_GID=2345 \
    -e CHU_USER=demo \
    -e CHU_HOME=/home/demo \
    "${TEST_NO_BACKEND_IMAGE}" \
    sh -lc 'printf unreachable'
  [ "$status" -ne 0 ]
  assert_output_contains "install gosu or su-exec" "${output}"
}
