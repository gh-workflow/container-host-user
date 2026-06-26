ARG BASE_IMAGE
# checkov:skip=CKV_DOCKER_7:Ensure the base image uses a non latest version tag
FROM ${BASE_IMAGE}

COPY bin/container-host-user /usr/local/bin/container-host-user

# hadolint ignore=DL3008,DL3041 # This is for tests only
RUN if [ -f /etc/alpine-release ]; then \
       apk add --no-cache shadow; \
     elif [ -f /etc/arch-release ]; then \
       pacman -Sy --noconfirm shadow; \
       pacman -Scc --noconfirm; \
     elif [ -f /etc/fedora-release ] || [ -f /etc/redhat-release ]; then \
       dnf install -y shadow-utils; \
       dnf clean all; \
     elif [ -f /etc/debian_version ]; then \
       apt-get update; \
       apt-get install -y --no-install-recommends passwd; \
       rm -rf /var/lib/apt/lists/*; \
     else \
       echo "unsupported base image" >&2; \
       exit 1; \
     fi

ENTRYPOINT ["/usr/local/bin/container-host-user"]
CMD ["sh"]
