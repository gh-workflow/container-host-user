#!/bin/sh
set -eu

# Test-local foreground launcher for the official httpd image.
# It mirrors the upstream helper but uses the absolute binary path so runtime
# PATH differences after user switching do not affect startup.

rm -f /usr/local/apache2/logs/httpd.pid

exec /usr/local/apache2/bin/httpd -DFOREGROUND "$@"
