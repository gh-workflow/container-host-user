#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
script="${repo_root}/bin/container-host-user"

chmod +x "${script}"
chmod +x "${repo_root}/tests/smoke.sh"

sh -n "${script}"
sh -n "${repo_root}/examples/example-entrypoint-hook.sh"

output=$("${script}" /bin/sh -c 'printf ok')
[ "${output}" = "ok" ]

printf '%s\n' "smoke tests passed"
