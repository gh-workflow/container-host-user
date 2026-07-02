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

## What You Add To An Image

You add one script to your image and call it from an entrypoint that still
starts as `root`.

This project is not tied to Debian or Ubuntu. It works across distributions as
long as the image provides:

- a POSIX `sh`
- the usual user/group management tools for that distro
- either `gosu` or `su-exec` to drop privileges

The examples below use `apt-get` only because it is familiar. On Alpine you
would typically install `su-exec`; on Debian/Ubuntu you would typically install
`gosu`.

```dockerfile
COPY bin/container-host-user /usr/local/bin/container-host-user
RUN apt-get update && apt-get install -y --no-install-recommends gosu
```

OCI image form:

```dockerfile
FROM ghcr.io/gh-workflow/container-host-user:latest AS container_host_user
FROM your-base-image

COPY --from=container_host_user \
  /usr/local/bin/container-host-user \
  /usr/local/bin/container-host-user
RUN apt-get update && apt-get install -y --no-install-recommends gosu
```

## Integration Patterns

You usually integrate `container-host-user` in one of two ways. The difference
is simply where you add the handoff to `container-host-user`.

### 1. Set `container-host-user` as the image entrypoint

This is the simplest form. Set the image entrypoint directly to
`container-host-user` and pass the real application entrypoint as its first
argument. `container-host-user` performs the user/group setup and then `exec`s
the real entrypoint.

```dockerfile
ENTRYPOINT ["/usr/local/bin/container-host-user", "/entrypoint.sh"]
```

In this pattern:

- `/usr/local/bin/container-host-user` handles the user/group setup
- `/entrypoint.sh` is your real application entrypoint
- container arguments are forwarded unchanged to `/entrypoint.sh`

At runtime, pass the host uid/gid:

```sh
docker run --rm \
  -e CHU_UID="$(id -u)" \
  -e CHU_GID="$(id -g)" \
  -e CHU_USER="${USER}" \
  -e CHU_HOME="${HOME}" \
  -v "$PWD:/workspace" \
  your-image
```

### 2. Add the handoff inside the existing entrypoint

Use this pattern when you want the image's existing entrypoint script to
contain the handoff logic directly. The entrypoint checks whether a user switch
is needed. If it is, it calls `container-host-user` once and then continues as
the target user.

Pattern for an existing entrypoint:

```sh
#!/bin/sh
set -eu

if [ "$(id -u)" -eq 0 ] &&
  [ -n "${CHU_UID:-}" ] &&
  [ -n "${CHU_GID:-}" ] &&
  [ "${CHU_USER_SWITCHED:-0}" != "1" ]; then
  exec /usr/local/bin/container-host-user /entrypoint.sh "$@"
fi

exec /entrypoint.sh "$@"
```

See [examples/example-entrypoint-hook.sh](examples/example-entrypoint-hook.sh)
for a concrete hook example.

## Where It Fits

This is meant for the common case where bind mounts should receive host-owned
files instead of `root`-owned files:

- the container starts as `root`
- the actual application can run as a non-root user

It avoids distro-specific assumptions where possible and chooses available user
management tools at runtime. The current test matrix covers Alpine, Arch Linux,
Debian, Fedora, and Ubuntu.

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
