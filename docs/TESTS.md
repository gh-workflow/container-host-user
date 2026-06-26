# Test Coverage

## Coverage Board

| Area                           | Covered | Notes                                                                                     | Evidence                                                                |
|--------------------------------|---------|-------------------------------------------------------------------------------------------|-------------------------------------------------------------------------|
| Shell safety                   | Yes     | Main script and example hook parse as `sh`.                                               | `tests/bats/smoke/00-smoke.bats`                                        |
| No-op behavior                 | Yes     | Unset runtime mapping and non-root invocation bypass provisioning.                        | `tests/bats/smoke/00-smoke.bats`,<br/>`tests/bats/runtime/10-user.bats` |
| Root pass-through              | Yes     | Explicit `0:0` mapping stays root.                                                        | `tests/bats/runtime/10-user.bats`                                       |
| Runtime user creation          | Yes     | Creates user, group, and home for requested uid/gid.                                      | `tests/bats/runtime/10-user.bats`                                       |
| Existing uid reuse             | Yes     | Reuses an existing uid instead of replacing it.                                           | `tests/bats/runtime/10-user.bats`                                       |
| Conflicting preferred name     | Yes     | Recreates conflicting preferred user/group names.                                         | `tests/bats/runtime/10-user.bats`                                       |
| Existing home reuse            | Yes     | Reuses and re-owns an existing home directory.                                            | `tests/bats/runtime/10-user.bats`                                       |
| Skeleton home files            | Yes     | Covers `CHU_COPY_SKEL=1` and `CHU_COPY_SKEL=0`.                                           | `tests/bats/runtime/50-skel.bats`                                       |
| Bind mount ownership           | Yes     | Writes bind-mounted files with requested ownership.                                       | `tests/bats/integration/20-mounts.bats`                                 |
| Supplemental groups            | Yes     | Adds extra gids, reuses existing gid groups, accepts duplicate and mixed-separator input. | `tests/bats/integration/30-groups.bats`                                 |
| Invalid numeric input          | Yes     | Rejects invalid `CHU_UID` and invalid `CHU_EXTRA_GIDS`.                                   | `tests/bats/contract/40-validation.bats`                                |
| Supported backend contract     | Yes     | Fails clearly when neither `gosu` nor `su-exec` is installed.                             | `tests/bats/contract/45-backend.bats`                                   |
| Hook integration               | Yes     | Covers the small-hook plus callback-to-entrypoint pattern.                                | `tests/bats/integration/15-hook.bats`                                   |
| Argument pass-through          | Yes     | Covers exact argv preservation for direct-entrypoint and hook-style integration.          | `tests/bats/integration/17-argv.bats`                                   |
| Real application pressure test | Yes     | Runs a remapped non-root startup flow on the official `httpd` image.                      | `tests/bats/integration/16-httpd.bats`                                  |
| Distro matrix                  | Yes     | Main behavior suite runs on Alpine, Arch Linux, Debian, Fedora, and Ubuntu.               | `tests/bats/setup_suite.sh`                                             |

## Coverage Areas

### Shell Safety

The suite checks that:

- `bin/container-host-user` parses as `sh`
- the example hook parses as `sh`

### Runtime Identity

The suite checks that:

- the script no-ops when runtime mapping is not requested
- root mapping remains root
- a runtime user/group/home is created for a new uid/gid
- an existing uid is reused
- conflicting preferred user/group names are recreated
- an existing home directory is re-owned and reused
- non-root invocation bypasses provisioning

### Home Content

The suite checks that:

- skeleton files are copied when enabled
- skeleton files are not copied when disabled
- existing home content is preserved

### Mounted Workspace Behavior

The suite checks that:

- bind-mounted files are written with the requested ownership

### Supplemental Group Access

The suite checks that:

- requested extra gids are added
- existing groups for those gids are reused
- duplicate gids and mixed separators do not break the final group set

### Contract and Failure Paths

The suite checks that:

- invalid numeric runtime input fails clearly
- unsupported privilege-drop setup fails clearly
- the supported backend contract is enforced: `gosu` or `su-exec`

### Integration Model

The suite checks that:

- the preferred integration pattern works: a small hook at the top of an
  existing entrypoint that calls back into the original entrypoint after the
  user switch

### Argument Pass-through

The suite checks that:

- direct-entrypoint images preserve the final command argv exactly
- hook-style integrations preserve the exact args passed to the original
  entrypoint
- empty args, leading dashes, spaces, and shell metacharacters survive the
  user switch unchanged

### Real Application Pressure Test

The suite checks that:

- the same hook-and-callback model also works on a widely used server image
- a remapped non-root startup flow can start `httpd` with a non-privileged
  port and a writable pid path

## Test Layout

User-facing runner:

- `tests/run.sh`

Suite bootstrap and helpers:

- `tests/bats/setup_suite.sh`
- `tests/bats/helpers/common.sh`

Grouped test files:

- `tests/bats/smoke/`
- `tests/bats/runtime/`
- `tests/bats/integration/`
- `tests/bats/contract/`

Image fixtures:

- `tests/images/Dockerfile`
- `tests/images/hook-callback.Dockerfile`
- `tests/images/httpd-pressure.Dockerfile`
- `tests/images/no-backend.Dockerfile`
- `tests/images/fixture-entrypoint.sh`
- `tests/images/httpd-foreground.sh`
- `tests/images/httpd-hook-entrypoint.sh`

## Distro Matrix

- Alpine
- Arch Linux
- Debian
- Fedora
- Ubuntu
