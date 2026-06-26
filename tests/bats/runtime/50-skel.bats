#!/usr/bin/env bats

# Skeleton-home copy behavior across supported base images.

load ../helpers/common.sh

@test "copies missing files from /etc/skel when enabled" {
  local image
  local -a lines

  for image in "${TEST_IMAGE_TAGS[@]}"; do
    run docker run --rm --entrypoint sh \
      -e CHU_UID=1234 \
      -e CHU_GID=2345 \
      -e CHU_USER=demo \
      -e CHU_HOME=/home/demo \
      -e CHU_COPY_SKEL=1 \
      "${image}" \
      -lc "
        set -eu
        mkdir -p /etc/skel
        printf 'from-skel\n' >/etc/skel/.skel_test
        mkdir -p /home/demo
        printf 'existing-home\n' >/home/demo/.keep_me
        /usr/local/bin/container-host-user sh -lc 'printf \"%s\n%s\n%s\n\" \"\$(cat /home/demo/.skel_test)\" \"\$(cat /home/demo/.keep_me)\" \"\$(stat -c %u:%g /home/demo/.skel_test)\"'
      "
    [ "$status" -eq 0 ]
    mapfile -t lines <<<"${output}"
    assert_output_eq "from-skel" "${lines[0]}" "${image}: skel file should be copied"
    assert_output_eq "existing-home" "${lines[1]}" "${image}: existing home file should be preserved"
    assert_output_eq "1234:2345" "${lines[2]}" "${image}: copied skel file ownership mismatch"
  done
}

@test "does not copy files from /etc/skel when disabled" {
  local image

  for image in "${TEST_IMAGE_TAGS[@]}"; do
    run docker run --rm --entrypoint sh \
      -e CHU_UID=1234 \
      -e CHU_GID=2345 \
      -e CHU_USER=demo \
      -e CHU_HOME=/home/demo \
      -e CHU_COPY_SKEL=0 \
      "${image}" \
      -lc "
        set -eu
        mkdir -p /etc/skel
        printf 'from-skel\n' >/etc/skel/.skel_test
        /usr/local/bin/container-host-user sh -lc 'test ! -e /home/demo/.skel_test'
      "
    [ "$status" -eq 0 ]
  done
}
