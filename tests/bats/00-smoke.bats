#!/usr/bin/env bats

# Fast smoke checks that do not need Docker image setup.

setup() {
  repo_root=$(CDPATH= cd -- "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)
}

@test "container-host-user script parses as sh" {
  run sh -n "${repo_root}/bin/container-host-user"
  [ "$status" -eq 0 ]
}

@test "example hook parses as sh" {
  run sh -n "${repo_root}/examples/example-entrypoint-hook.sh"
  [ "$status" -eq 0 ]
}

@test "script no-ops outside root or docker setup" {
  run "${repo_root}/bin/container-host-user" /bin/sh -c 'printf ok'
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}
