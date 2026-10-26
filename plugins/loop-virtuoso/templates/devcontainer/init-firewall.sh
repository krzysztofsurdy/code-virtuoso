#!/bin/bash
# Default-deny egress firewall for the Claude Code devcontainer. Runs as root
# on every container start (postStartCommand); the node user may sudo this one
# script and nothing else. Written by /loop-virtuoso:scaffold devcontainer.
#
# Allowed out: DNS to the container's resolvers, loopback, the Docker host
# network, GitHub (ranges from api.github.com/meta) and the hosts listed in
# ALLOWED_DOMAINS below. Everything else is rejected, IPv6 included.
#
# Customize ALLOWED_DOMAINS for your registries. Domains are resolved once, at
# start; a host behind a CDN that rotates addresses may need a restart.
set -euo pipefail
IFS=$'\n\t'

ALLOWED_DOMAINS=(
  # Claude Code
  api.anthropic.com
  statsig.com
  sentry.io
  # npm
  registry.npmjs.org
  # Composer / Packagist (dist archives come from GitHub, allowed below)
  packagist.org
  repo.packagist.org
  # VS Code extensions and server
  marketplace.visualstudio.com
  vscode.blob.core.windows.net
  update.code.visualstudio.com
)

fail() { echo "init-firewall: $*" >&2; exit 1; }

# Docker's embedded DNS (127.0.0.11) lives in NAT rules; keep them across the flush.
docker_dns_rules="$(iptables-save -t nat | grep '127\.0\.0\.11' || true)"

# Open first, so a re-run in a running container can still reach api.github.com.
iptables -P INPUT ACCEPT; iptables -P FORWARD ACCEPT; iptables -P OUTPUT ACCEPT
iptables -F; iptables -X
iptables -t nat -F; iptables -t nat -X
iptables -t mangle -F; iptables -t mangle -X
ipset destroy allowed-hosts 2>/dev/null || true

if [[ -n "$docker_dns_rules" ]]; then
  iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
  iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
  while IFS= read -r rule; do
    [[ "$rule" == -A* ]] || continue
    IFS=' ' read -r -a args <<< "$rule"
    iptables -t nat "${args[@]}"
  done <<< "$docker_dns_rules"
fi

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# DNS only to the configured resolvers, so DNS cannot reach arbitrary servers.
while read -r ns; do
  [[ -n "$ns" ]] || continue
  iptables -A OUTPUT -p udp -d "$ns" --dport 53 -j ACCEPT
  iptables -A OUTPUT -p tcp -d "$ns" --dport 53 -j ACCEPT
done < <(awk '$1 == "nameserver" && $2 ~ /^[0-9.]+$/ {print $2}' /etc/resolv.conf)

ipset create allowed-hosts hash:net

meta="$(curl -fsS --connect-timeout 10 https://api.github.com/meta)" || fail "cannot fetch https://api.github.com/meta"
echo "$meta" | jq -e '.web and .api and .git' >/dev/null || fail "api.github.com/meta is missing web, api or git ranges"
while read -r cidr; do
  [[ "$cidr" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]] || fail "unexpected GitHub range: $cidr"
  ipset add allowed-hosts "$cidr" -exist
done < <(echo "$meta" | jq -r '(.web + .api + .git)[] | select(contains(":") | not)' | aggregate -q)

for domain in "${ALLOWED_DOMAINS[@]}"; do
  ips="$(dig +short A "$domain" | grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' || true)"
  [[ -n "$ips" ]] || fail "cannot resolve $domain"
  while read -r ip; do
    ipset add allowed-hosts "$ip" -exist
  done <<< "$ips"
done

# The Docker host network, for VS Code and port forwarding.
host_ip="$(ip route | awk '/^default/ {print $3; exit}')"
[[ -n "$host_ip" ]] || fail "cannot find the default route"
host_net="${host_ip%.*}.0/24"
iptables -A INPUT -s "$host_net" -j ACCEPT
iptables -A OUTPUT -d "$host_net" -j ACCEPT

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m set --match-set allowed-hosts dst -j ACCEPT
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

if command -v ip6tables >/dev/null 2>&1 && ip6tables -L >/dev/null 2>&1; then
  ip6tables -F
  ip6tables -A INPUT -i lo -j ACCEPT
  ip6tables -A OUTPUT -o lo -j ACCEPT
  ip6tables -P INPUT DROP
  ip6tables -P FORWARD DROP
  ip6tables -P OUTPUT DROP
fi

if curl -fsS --connect-timeout 5 https://example.com >/dev/null 2>&1; then
  fail "verification failed: https://example.com is reachable"
fi
curl -fsS --connect-timeout 5 https://api.github.com/zen >/dev/null 2>&1 \
  || fail "verification failed: https://api.github.com is not reachable"
echo "init-firewall: egress limited to GitHub and ${#ALLOWED_DOMAINS[@]} allowed domains"
