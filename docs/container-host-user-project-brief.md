# container-host-user -- Project Brief

## Goal

Create a small, focused open source project around a reusable shell
script that solves a common container problem:

> Containers writing **root-owned files** to host directories mounted
> into the container.

The project should provide a robust, portable way to run the actual
application as the appropriate runtime user.

------------------------------------------------------------------------

# Repository

Repository:

`https://github.com/Wuodan/container-host-user`

Current working title:

**container-host-user**

This is preferred over earlier names such as `container-runtime-user`
because it reflects the user's mental model instead of the
implementation.

The implementation is "runtime user provisioning".

The problem users search for is:

-   root-owned files
-   bind mount permissions
-   host user
-   Docker/Podman UID/GID
-   arbitrary runtime UID

The repository name should stay focused on that user problem.

------------------------------------------------------------------------

# Repository description

Current preferred tagline:

> **Run container images as the host user to avoid root-owned files on
> bind mounts.**

This is intentionally user-focused instead of implementation-focused.

------------------------------------------------------------------------

# Project scope

The project is intentionally small.

Initially it contains one primary shell script plus tests and
documentation.

Possible later additions:

-   GitHub Action
-   OCI image containing the script
-   Release assets
-   Examples
-   CI
-   Extensive tests

The repository should remain centered around solving one problem well.

------------------------------------------------------------------------

# Existing implementation

The new project should be based on existing work.

Reference implementations exist in the user's projects, including:

-   MegaLinter
-   AICage

The existing logic has already been solved and should be generalized
instead of rewritten.

Goals:

-   remove project-specific naming
-   improve portability
-   improve documentation
-   improve tests

------------------------------------------------------------------------

# Supported platforms

Primary targets:

-   Alpine
-   Debian
-   Ubuntu

The design should avoid unnecessary distro-specific assumptions.

------------------------------------------------------------------------

# What the script does

High-level behaviour:

1.  Starts as root.
2.  Determines desired runtime UID/GID.
3.  Reuses existing user if possible.
4.  Creates user/group if needed.
5.  Creates or fixes HOME.
6.  Performs distro-specific user/group handling.
7.  Switches user.
8.  `exec`s the real entrypoint.

The script should remain simple and dependency-light.

------------------------------------------------------------------------

# Distribution strategy

The project should support multiple ways of consuming it.

## 1. GitHub Releases

Versioned release assets.

Users may either:

-   pin a version
-   download `latest`

Pinned versions are recommended for reproducibility.

------------------------------------------------------------------------

## 2. OCI image

Publish a tiny OCI image containing the script.

Typical usage:

COPY --from=`<image>`{=html} ...

This is optional but useful for users who prefer OCI-native workflows.

------------------------------------------------------------------------

## 3. GitHub Action

A small action that makes using the script inside GitHub Actions easy.

Benefits:

-   convenience
-   Dependabot update notifications for the action

------------------------------------------------------------------------

All three distribution methods should coexist.

------------------------------------------------------------------------

# Philosophy

The project should encourage:

-   vendoring
-   reproducible builds
-   simple integration

No package manager (npm, PyPI, Snap, etc.) is required.

The project should not become tied to one ecosystem.

------------------------------------------------------------------------

# License

Preferred license:

Apache 2.0

Reasons:

-   permissive
-   commercial-friendly
-   explicit patent grant
-   encourages vendoring

------------------------------------------------------------------------

# Design principles

-   KISS
-   portable POSIX shell where practical
-   minimal dependencies
-   readable code
-   well documented
-   thoroughly tested

Avoid unnecessary abstractions.

------------------------------------------------------------------------

# Documentation direction

The README should explain the problem first.

Users typically encounter symptoms like:

-   root-owned files
-   permission denied
-   UID/GID mismatch
-   bind mount ownership issues

Only afterwards explain how the implementation works.

The project should market the solution, not the implementation.

------------------------------------------------------------------------

# Long-term vision

Become the standard reusable implementation for:

"Run container images as the host user."

Instead of every project maintaining its own slightly different
runtime-user script, projects should be able to reuse this
implementation.
