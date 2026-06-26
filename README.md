# container-host-user

Run container images as the host user to avoid root-owned files on bind mounts.

## Problem

Many container images start as `root`. When those containers write into a bind
mount from the host, they often leave behind `root`-owned files. That breaks
local development, CI workspaces, and editor tooling.

This project provides a small shell script that:

1. Starts as `root`.
2. Resolves the desired runtime UID/GID.
3. Reuses or creates a matching user/group.
4. Prepares a usable home directory.
5. Switches to that runtime user.
6. `exec`s the real entrypoint command.

It is designed to be dropped into existing images and existing entrypoints.

## Supported targets

Primary targets:

- Alpine
- Debian
- Fedora
- Ubuntu

Additional matrix coverage:

- Arch Linux

The script avoids distro-specific assumptions where possible and chooses the
available tooling at runtime.

## Files

- `bin/container-host-user`: reusable runtime-user provisioning script
- `examples/example-entrypoint-hook.sh`: entrypoint hook pattern
- `tests/run.sh`: wrapper to run the full test suite
- `docs/TESTS.md`: skimmable test coverage map
- `tests/bats/`: Docker-based cross-distro tests grouped by concern

## Usage

Copy the script into your image and call it from an entrypoint that still starts
as `root`. Your image must also provide either `gosu` or `su-exec`.

```dockerfile
COPY bin/container-host-user /usr/local/bin/container-host-user
RUN apt-get update && apt-get install -y --no-install-recommends gosu
```

Minimal wrapper:

```sh
#!/bin/sh
set -eu

exec /usr/local/bin/container-host-user /entrypoint.sh "$@"
```

Typical runtime configuration:

```sh
docker run --rm \
  -e CHU_UID="$(id -u)" \
  -e CHU_GID="$(id -g)" \
  -e CHU_USER="${USER}" \
  -e CHU_HOME="${HOME}" \
  -v "$PWD:/workspace" \
  your-image
```

## Environment variables

- `CHU_UID`: target runtime UID. If unset, the script becomes a no-op.
- `CHU_GID`: target runtime GID. If unset, the script becomes a no-op.
- `CHU_USER`: preferred runtime username. Default: `hostuser`
- `CHU_HOME`: preferred runtime home. Default: `/home/$CHU_USER`, or `/root`
  for UID `0`
- `CHU_COPY_SKEL`: copy missing files from `/etc/skel` into the home directory.
  Default: `1`
- `CHU_EXTRA_GIDS`: comma- or space-separated supplemental GIDs to create or
  reuse and add to the runtime user. Useful for mounted resources such as
  Docker sockets.

## Behavior

- If the process is not running as `root`, it directly `exec`s the target
  command.
- If `CHU_UID` or `CHU_GID` is missing, it directly `exec`s the target command.
- If a user with the requested UID already exists, it is reused.
- If a group with the requested GID already exists, it is reused.
- If the preferred user or group name already exists with conflicting IDs, the
  script removes and recreates that account.
- The script creates the target home directory and attempts to own it.
- The script can add the runtime user to supplemental groups via
  `CHU_EXTRA_GIDS`.
- The script requires one supported privilege-drop backend:
  `gosu` or `su-exec`.

## Example integration

Pattern for an existing entrypoint:

```sh
#!/bin/sh
set -eu

if [ "$(id -u)" -eq 0 ] \
  && [ -n "${CHU_UID:-}" ] \
  && [ -n "${CHU_GID:-}" ] \
  && [ "${CHU_USER_SWITCHED:-0}" != "1" ]; then
  exec /usr/local/bin/container-host-user /entrypoint.sh "$@"
fi

exec /entrypoint.sh "$@"
```

See [examples/example-entrypoint-hook.sh](examples/example-entrypoint-hook.sh)
for a concrete hook example.

## Tests

Run:

```sh
./tests/run.sh
```

The `bats` suite includes shell syntax checks, a direct no-op execution check,
and Docker-based Alpine, Arch Linux, Debian, Fedora, and Ubuntu integration
coverage against real container entrypoints.

See [docs/TESTS.md](docs/TESTS.md) for the coverage map by use-case group.
