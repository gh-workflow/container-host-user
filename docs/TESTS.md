# Test Coverage

Test coverage for `container-host-user`.

## Coverage Map

### 1. Baseline Safety

Coverage:

- the main script parses as plain `sh`
- the example hook parses as plain `sh`
- the script safely no-ops when used outside its intended root-switch context

Files:

- `tests/bats/smoke/00-smoke.bats`

### 2. Runtime User Provisioning

Coverage:

- unset `CHU_UID`/`CHU_GID` no-op correctly
- explicit root mapping stays root
- a runtime user/home is created correctly
- an existing UID is reused instead of being replaced
- a conflicting preferred user/group name is recreated
- an existing home directory is reused and re-owned
- non-root invocation bypasses provisioning
- `/etc/skel` copying works when enabled and stays off when disabled

Files:

- `tests/bats/runtime/10-user.bats`
- `tests/bats/runtime/50-skel.bats`

### 3. Integration Patterns

Coverage:

- the preferred hook-and-callback entrypoint pattern works
- bind-mounted writes land with the requested ownership
- supplemental groups are applied for mounted-resource access
- existing supplemental gid groups are reused
- duplicate and mixed-separator extra gid input stays usable

Files:

- `tests/bats/integration/15-hook.bats`
- `tests/bats/integration/20-mounts.bats`
- `tests/bats/integration/30-groups.bats`

### 4. Contract and Failure Paths

Coverage:

- invalid numeric inputs fail clearly
- unsupported privilege-drop setup fails clearly
- the supported backend contract is enforced: `gosu` or `su-exec`

Files:

- `tests/bats/contract/40-validation.bats`
- `tests/bats/contract/45-backend.bats`

## Distro Matrix

The main suite is intended to run each relevant behavior on:

- Alpine
- Debian
- Fedora
- Ubuntu

There are also dedicated fixture images for:

- hook-and-callback entrypoint integration
- missing-backend failure behavior

## Test Structure

Top-level user entrypoint:

- `tests/run.sh`

Suite bootstrap and shared helpers:

- `tests/bats/setup_suite.bash`
- `tests/bats/helpers/common.bash`

Image fixtures:

- `tests/images/Dockerfile`
- `tests/images/hook-callback.Dockerfile`
- `tests/images/no-backend.Dockerfile`
- `tests/images/fixture-entrypoint.sh`

## Reading Order

If you want the fastest overview:

1. `docs/TESTS.md`
2. `tests/bats/runtime/10-user.bats`
3. `tests/bats/integration/15-hook.bats`
4. `tests/bats/contract/45-backend.bats`
