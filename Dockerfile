FROM ghcr.io/openclaw/openclaw:latest

USER root

ARG YQ_VERSION=v4.53.3
ARG HIMALAYA_VERSION=v1.2.0

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      openssh-client \
      jq \
      iputils-ping \
      netcat-openbsd \
      nmap \
      dnsutils \
      python3-pip \
      rsync \
      htop \
      nano \
      vim-tiny \
      unzip \
      zip \
      wget \
      iproute2 \
      psmisc \
      strace \
      tcpdump \
      traceroute \
      ripgrep \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --break-system-packages paramiko==5.0.0

RUN ARCH="$(dpkg --print-architecture)" \
    && curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}" \
       -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq \
     && yq --version

RUN ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in \
         amd64) HARCH=x86_64 ;; \
         arm64) HARCH=aarch64 ;; \
         *) echo "unsupported arch: $ARCH" >&2; exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/pimalaya/himalaya/releases/download/${HIMALAYA_VERSION}/himalaya.${HARCH}-linux.tgz" \
       -o /tmp/himalaya.tgz \
    && tar -xzf /tmp/himalaya.tgz -C /usr/local/bin himalaya \
    && chmod +x /usr/local/bin/himalaya \
    && rm -f /tmp/himalaya.tgz \
    && himalaya --version

USER node
