FROM ghcr.io/openclaw/openclaw:latest

USER root

ARG YQ_VERSION=v4.45.1

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

RUN python3 -m pip install --no-cache-dir --break-system-packages paramiko

RUN ARCH="$(dpkg --print-architecture)" \
    && curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}" \
       -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq \
    && yq --version

USER node
