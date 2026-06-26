#!/usr/bin/env bats

# Argument pass-through behavior for direct-entrypoint and hook-style images.

load ../helpers/common.sh

assert_argv_contract() {
  local output_blob="$1"
  local context="$2"
  local -a lines

  mapfile -t lines <<<"${output_blob}"
  assert_output_eq "1234" "${lines[0]#uid=}" "${context}: uid mismatch"
  assert_output_eq "2345" "${lines[1]#gid=}" "${context}: gid mismatch"
  assert_output_eq "5" "${lines[2]#argc=}" "${context}: argc mismatch"
  assert_output_eq "arg1=<--flag>" "${lines[3]}" "${context}: arg1 mismatch"
  assert_output_eq "arg2=<two words>" "${lines[4]}" "${context}: arg2 mismatch"
  assert_output_eq "arg3=<>" "${lines[5]}" "${context}: arg3 mismatch"
  assert_output_eq "arg4=<semi;colon>" "${lines[6]}" "${context}: arg4 mismatch"
  assert_output_eq "arg5=<*>" "${lines[7]}" "${context}: arg5 mismatch"
}

@test "direct entrypoint preserves exact command argv" {
  local image

  for image in "${TEST_IMAGE_TAGS[@]}"; do
    run docker run --rm \
      -e CHU_UID=1234 \
      -e CHU_GID=2345 \
      -e CHU_USER=demo \
      -e CHU_HOME=/home/demo \
      "${image}" \
      sh -lc 'printf "uid=%s\ngid=%s\nargc=%s\n" "$(id -u)" "$(id -g)" "$#"; index=1; for arg in "$@"; do printf "arg%s=<%s>\n" "${index}" "${arg}"; index=$((index + 1)); done' argv0 \
      '--flag' 'two words' '' 'semi;colon' '*'
    [ "$status" -eq 0 ]
    assert_argv_contract "${output}" "${image}: direct entrypoint"
  done
}

@test "hook integration preserves exact args passed to the original entrypoint" {
  local image

  for image in "${TEST_HOOK_IMAGE_TAGS[@]}"; do
    run docker run --rm \
      -e MEGALINTER_UID=1234 \
      -e MEGALINTER_GID=2345 \
      -e MEGALINTER_USER=demo \
      -e HOME=/home/demo \
      -e FIXTURE_MODE=print-args \
      "${image}" \
      '--flag' 'two words' '' 'semi;colon' '*'
    [ "$status" -eq 0 ]
    assert_argv_contract "${output}" "${image}: hook entrypoint"
  done
}
