# Sandbox for running Claude Code (and loop-virtuoso Mode B) with a wide
# allowlist. Written by /loop-virtuoso:scaffold devcontainer. Modelled on the
# reference devcontainer in https://github.com/anthropics/claude-code/tree/main/.devcontainer
#
# What it gives you:
#   - a non-root user (node) that can run exactly one command as root: the firewall script
#   - a default-deny egress firewall with an allowlist (init-firewall.sh, run on every start)
#   - no host credentials: no ~/.ssh, ~/.aws, ~/.config/gcloud or ~/.azure mounts,
#     and SSH agent forwarding is cleared in devcontainer.json
#   - Claude Code, git, gh and jq
#
# What to customize:
#   1. Language toolchain: uncomment the OPTIONAL PHP block below, or add your own
#      (Python, Go, ...) in the same place, as root.
#   2. Allowed hosts: ALLOWED_DOMAINS in init-firewall.sh. Add your package mirror,
#      private registry or API sandbox there; everything else stays blocked.
#   3. VS Code still copies your ~/.gitconfig and forwards git credentials unless you
#      turn that off in your own VS Code user settings:
#        "dev.containers.copyGitConfig": false,
#        "dev.containers.gitCredentialHelperConfigLocation": "none"
#      Never add a mount of a host credential directory to devcontainer.json.
#   4. Versions: NODE_VERSION and CLAUDE_CODE_VERSION in devcontainer.json.

ARG NODE_VERSION=24
FROM node:${NODE_VERSION}-bookworm

ARG TZ=UTC
ENV TZ="$TZ"

RUN apt-get update && apt-get install -y --no-install-recommends \
    aggregate \
    ca-certificates \
    curl \
    dnsutils \
    gh \
    git \
    iproute2 \
    ipset \
    iptables \
    jq \
    less \
    make \
    procps \
    sudo \
    unzip \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- OPTIONAL: PHP toolchain --------------------------------------------------
# Uncomment for PHP projects. Debian bookworm ships PHP 8.2; for 8.3+ add the
# packages.sury.org repository first. Allow its host in init-firewall.sh only if
# you install packages after the firewall is up (this block runs at build time).
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     php-cli php-curl php-intl php-mbstring php-xml php-zip \
#   && apt-get clean && rm -rf /var/lib/apt/lists/*
# COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
# ------------------------------------------------------------------------------

RUN mkdir -p /workspace /commandhistory /home/node/.claude /usr/local/share/npm-global \
  && touch /commandhistory/.bash_history \
  && chown -R node:node /workspace /commandhistory /home/node/.claude /usr/local/share/npm-global

COPY init-firewall.sh /usr/local/bin/init-firewall.sh
RUN chmod 0755 /usr/local/bin/init-firewall.sh \
  && echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall \
  && chmod 0440 /etc/sudoers.d/node-firewall

USER node
WORKDIR /workspace

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin
ENV HISTFILE=/commandhistory/.bash_history
ENV PROMPT_COMMAND="history -a"

ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}
