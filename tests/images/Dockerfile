ARG BASE_IMAGE=alpine:3.22
FROM ${BASE_IMAGE}

COPY bin/container-host-user /usr/local/bin/container-host-user

RUN if [ -f /etc/alpine-release ]; then \
       apk add --no-cache shadow su-exec; \
     elif [ -f /etc/debian_version ]; then \
       apt-get update; \
       apt-get install -y --no-install-recommends passwd util-linux; \
       rm -rf /var/lib/apt/lists/*; \
     else \
       echo "unsupported base image" >&2; \
       exit 1; \
     fi

ENTRYPOINT ["/usr/local/bin/container-host-user"]
CMD ["sh"]
