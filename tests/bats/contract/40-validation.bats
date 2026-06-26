#!/usr/bin/env bats

# Input validation and failure behavior across supported base images.

load ../helpers/common.sh

@test "rejects non-numeric CHU_UID" {
  local image

  for image in "${TEST_IMAGE_TAGS[@]}"; do
    run docker run --rm \
      -e CHU_UID=not-a-number \
      -e CHU_GID=1234 \
      "${image}" \
      sh -lc 'printf unreachable'
    [ "$status" -ne 0 ]
    assert_output_contains "CHU_UID and CHU_GID must be numeric" "${output}"
  done
}

@test "rejects invalid CHU_EXTRA_GIDS" {
  local image

  for image in "${TEST_IMAGE_TAGS[@]}"; do
    run docker run --rm \
      -e CHU_UID=1234 \
      -e CHU_GID=2345 \
      -e CHU_EXTRA_GIDS='2999,broken' \
      "${image}" \
      sh -lc 'printf unreachable'
    [ "$status" -ne 0 ]
    assert_output_contains "CHU_EXTRA_GIDS must be a comma- or space-separated list of numeric gids" "${output}"
  done
}
