#!/usr/bin/env bats

# Hook-and-callback integration behavior across supported base images.

load ../helpers/common.sh

@test "existing entrypoint hook switches user and returns to the original entrypoint" {
  local image
  local -a lines

  for image in "${TEST_HOOK_IMAGE_TAGS[@]}"; do
    run docker run --rm \
      -e EXAMPLE_UID=1234 \
      -e EXAMPLE_GID=2345 \
      -e EXAMPLE_USER=demo \
      -e HOME=/home/demo \
      "${image}" \
      sh -lc 'printf "%s\n%s\n%s\n%s\n" "$(id -u)" "$(id -g)" "$(id -un)" "$HOME"'
    [ "$status" -eq 0 ]
    mapfile -t lines <<<"${output}"
    assert_output_eq "1234" "${lines[0]}" "${image}: hook uid mismatch"
    assert_output_eq "2345" "${lines[1]}" "${image}: hook gid mismatch"
    assert_output_eq "demo" "${lines[2]}" "${image}: hook user mismatch"
    assert_output_eq "/home/demo" "${lines[3]}" "${image}: hook home mismatch"
  done
}
