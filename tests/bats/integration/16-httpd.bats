#!/usr/bin/env bats

# Real-application pressure test using the official httpd image.

load ../helpers/common.sh

@test "httpd hook fixture starts as remapped non-root user" {
  local container_name
  local -a lines

  container_name="container-host-user-httpd-test-$$"
  trap 'docker rm -f "${container_name}" >/dev/null 2>&1 || true' EXIT

  run docker run -d --name "${container_name}" \
    -e HTTPD_UID=1234 \
    -e HTTPD_GID=2345 \
    -e HTTPD_USER=webapp \
    -e HTTPD_HOME=/home/webapp \
    -p 8080 \
    "${TEST_HTTPD_IMAGE}"
  [ "$status" -eq 0 ]

  run docker exec "${container_name}" sh -lc '
    httpd_pid="$(cat /tmp/httpd.pid)"
    runtime_uid="$(stat -c "%u" /proc/${httpd_pid})"
    runtime_gid="$(stat -c "%g" /proc/${httpd_pid})"
    runtime_entry="$(awk -F: -v uid="${runtime_uid}" '"'"'$3 == uid { print $1 ":" $6; exit }'"'"' /etc/passwd)"
    printf "%s\n%s\n%s\n%s\n%s\n" \
      "${runtime_uid}" \
      "${runtime_gid}" \
      "${runtime_entry%%:*}" \
      "${runtime_entry#*:}" \
      "$(stat -c "%u:%g" /tmp/httpd.pid)"
  '
  [ "$status" -eq 0 ]
  mapfile -t lines <<<"${output}"
  assert_output_eq "1234" "${lines[0]}" "httpd fixture uid mismatch"
  assert_output_eq "2345" "${lines[1]}" "httpd fixture gid mismatch"
  assert_output_eq "webapp" "${lines[2]}" "httpd fixture user mismatch"
  assert_output_eq "/home/webapp" "${lines[3]}" "httpd fixture home mismatch"
  assert_output_eq "1234:2345" "${lines[4]}" "httpd fixture pid ownership mismatch"

  run docker exec "${container_name}" sh -lc '
    wget -q -O - http://127.0.0.1:8080/ &&
      printf "\nHOME_OWNER=%s\n" "$(stat -c "%u:%g" /home/webapp)"
  '
  [ "$status" -eq 0 ]
  [[ "${output}" == *"It works! Apache httpd"* ]]
  [[ "${output}" == *$'\nHOME_OWNER=1234:2345' ]]

  docker rm -f "${container_name}" >/dev/null 2>&1 || true
  trap - EXIT
}
