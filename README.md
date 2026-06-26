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
- Ubuntu

The script avoids distro-specific assumptions where possible and chooses the
available tooling at runtime.

## Files

- `bin/container-host-user`: reusable runtime-user provisioning script
- `examples/megalinter-entrypoint-hook.sh`: entrypoint hook pattern
- `tests/smoke.sh`: basic smoke tests
- `tests/integration.sh`: Docker-based cross-distro integration tests

## Usage

Copy the script into your image and call it from an entrypoint that still starts
as `root`.

```dockerfile
COPY bin/container-host-user /usr/local/bin/container-host-user
RUN chmod +x /usr/local/bin/container-host-user
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
- `CHU_DEBUG`: print debug logs. Default: `0`

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
- The script uses the first available privilege-drop backend from:
  `su-exec`, `gosu`, `setpriv`, `runuser`, `su`.

## Example integration

Pattern for an existing entrypoint:

```sh
#!/bin/sh
set -eu

if [ "$(id -u)" -eq 0 ] \
  && [ -n "${CHU_UID:-}" ] \
  && [ -n "${CHU_GID:-}" ] \
  && [ "${CHU_USER_SWITCHED:-0}" != "1" ]; then
  export CHU_USER_SWITCHED=1
  exec /usr/local/bin/container-host-user /entrypoint.sh "$@"
fi

exec /entrypoint.sh "$@"
```

See [examples/megalinter-entrypoint-hook.sh](/home/stefan/development/github/Wuodan/container-host-user/examples/megalinter-entrypoint-hook.sh)
for a concrete hook example.

## Tests

Run:

```sh
sh tests/smoke.sh
./tests/integration.sh
```

The smoke tests validate syntax and basic no-op behavior. The integration tests
build dedicated Alpine, Debian, and Ubuntu images and validate runtime-user
behavior against real container entrypoints.
