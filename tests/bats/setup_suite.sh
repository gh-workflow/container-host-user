#!/usr/bin/env bash
set -euo pipefail

# bats suite bootstrap.
# bats loads this file automatically before executing tests in this directory.

# Repository-local inputs for building the test image matrix.
repo_root=$(CDPATH= cd -- "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)
readonly repo_root
readonly dockerfile="${repo_root}/tests/images/Dockerfile"
readonly project_tag="container-host-user-test"

# Image matrix used by the integration suite.
readonly -a test_images=(
  "${project_tag}:alpine|alpine:3.22"
  "${project_tag}:debian|debian:bookworm-slim"
  "${project_tag}:ubuntu|ubuntu:24.04"
)

# Build every test image once before the suite starts.
build_test_images() {
  local image_def tag base_image
  for image_def in "${test_images[@]}"; do
    IFS='|' read -r tag base_image <<<"${image_def}"
    echo "building ${tag} from ${base_image}" >&3
    docker build \
      --build-arg "BASE_IMAGE=${base_image}" \
      -t "${tag}" \
      -f "${dockerfile}" \
      "${repo_root}" >/dev/null
  done
}

# bats entrypoint that runs before any test files in this suite.
setup_suite() {
  build_test_images
}
