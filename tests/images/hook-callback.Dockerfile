ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG GOSU_VERSION=1.17

COPY bin/container-host-user /usr/local/bin/container-host-user
COPY examples/megalinter-entrypoint-hook.sh /hook-entrypoint.sh
COPY tests/images/fixture-entrypoint.sh /entrypoint.sh

RUN chmod +x /usr/local/bin/container-host-user /hook-entrypoint.sh /entrypoint.sh \
  && if [ -f /etc/alpine-release ]; then \
       apk add --no-cache shadow su-exec; \
     elif [ -f /etc/fedora-release ] || [ -f /etc/redhat-release ]; then \
       dnf install -y ca-certificates curl shadow-utils; \
       arch="$(uname -m)"; \
       case "${arch}" in \
         x86_64) gosu_arch='amd64' ;; \
         aarch64) gosu_arch='arm64' ;; \
         *) echo "unsupported architecture for gosu: ${arch}" >&2; exit 1 ;; \
       esac; \
       curl -fsSL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${gosu_arch}" -o /usr/local/bin/gosu; \
       chmod +x /usr/local/bin/gosu; \
       gosu nobody true; \
       dnf clean all; \
     elif [ -f /etc/debian_version ]; then \
       apt-get update; \
       apt-get install -y --no-install-recommends gosu passwd; \
       rm -rf /var/lib/apt/lists/*; \
     else \
       echo "unsupported base image" >&2; \
       exit 1; \
     fi

ENTRYPOINT ["/hook-entrypoint.sh"]
CMD ["sh"]
