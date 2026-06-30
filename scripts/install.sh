#!/usr/bin/env bash
# install.sh — resolve / download / activate the Bynk toolchain.
#
# Subcommands (each is a separate composite step so caching can sit between
# "resolve" and "download"):
#   resolve   Determine the version tag, target triple, archive extension, and
#             install dir. Writes step outputs: version, target, ext, bindir.
#   download  Fetch the release archive + SHA256SUMS, verify, extract to bindir.
#   activate  Add bindir to PATH (GITHUB_PATH) and print bynkc --version.
set -euo pipefail

# --- helpers ---------------------------------------------------------------

die() { echo "::error::setup-bynk: $*" >&2; exit 1; }

# sha256 of a file, portable across Linux (sha256sum) and macOS (shasum).
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# Map the runner OS + arch to Bynk's release target triple.
target_triple() {
  local os arch
  case "${RUNNER_OS:-$(uname -s)}" in
    Linux)   os=linux ;;
    macOS|Darwin) os=macos ;;
    Windows|MINGW*|MSYS*|CYGWIN*) os=windows ;;
    *) die "unsupported OS: ${RUNNER_OS:-$(uname -s)}" ;;
  esac
  case "${RUNNER_ARCH:-$(uname -m)}" in
    X64|x86_64|amd64) arch=x86_64 ;;
    ARM64|arm64|aarch64) arch=aarch64 ;;
    *) die "unsupported arch: ${RUNNER_ARCH:-$(uname -m)}" ;;
  esac
  case "$os" in
    linux)   echo "${arch}-unknown-linux-gnu" ;;
    macos)   echo "${arch}-apple-darwin" ;;
    windows) echo "${arch}-pc-windows-msvc" ;;
  esac
}

# --- subcommands -----------------------------------------------------------

cmd_resolve() {
  local repo="${INPUT_REPOSITORY:?}" want="${INPUT_VERSION:-latest}" version target ext bindir
  target="$(target_triple)"
  case "$target" in
    *windows*) ext="zip" ;;
    *)         ext="tar.gz" ;;
  esac

  if [ "$want" = "latest" ]; then
    local api="https://api.github.com/repos/${repo}/releases/latest"
    local auth=()
    [ -n "${GH_TOKEN:-}" ] && auth=(-H "Authorization: Bearer ${GH_TOKEN}")
    version="$(curl -fsSL "${auth[@]}" "$api" \
      | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
    [ -n "$version" ] || die "could not resolve the latest release from ${repo}"
  else
    # Normalise "0.107.0" -> "v0.107.0"; leave an existing leading v alone.
    case "$want" in v*) version="$want" ;; *) version="v${want}" ;; esac
  fi

  bindir="${RUNNER_TOOL_CACHE:-${RUNNER_TEMP:-/tmp}}/bynk/${version}/${target}"

  {
    echo "version=${version}"
    echo "target=${target}"
    echo "ext=${ext}"
    echo "bindir=${bindir}"
  } >> "${GITHUB_OUTPUT:?}"
  echo "Resolved Bynk ${version} for ${target}"
}

cmd_download() {
  local repo="${INPUT_REPOSITORY:?}" version="${RESOLVED_VERSION:?}" target="${RESOLVED_TARGET:?}"
  local ext="${RESOLVED_EXT:?}" bindir="${RESOLVED_BINDIR:?}"
  local stem="bynk-${version}-${target}"
  local archive="${stem}.${ext}"
  local base="https://github.com/${repo}/releases/download/${version}"
  local tmp; tmp="$(mktemp -d)"
  local auth=()
  [ -n "${GH_TOKEN:-}" ] && auth=(-H "Authorization: Bearer ${GH_TOKEN}")

  echo "Downloading ${archive}"
  curl -fSL "${auth[@]}" -o "${tmp}/${archive}" "${base}/${archive}" \
    || die "download failed: ${base}/${archive}"
  curl -fSL "${auth[@]}" -o "${tmp}/SHA256SUMS" "${base}/SHA256SUMS" \
    || die "download failed: ${base}/SHA256SUMS"

  # Verify against the SHA256SUMS manifest (basenames, two-space separated).
  local want got
  want="$(grep -E "  ${archive}\$" "${tmp}/SHA256SUMS" | awk '{print $1}' | head -n1)"
  [ -n "$want" ] || die "no checksum for ${archive} in SHA256SUMS"
  got="$(sha256_of "${tmp}/${archive}")"
  [ "$want" = "$got" ] || die "checksum mismatch for ${archive} (want ${want}, got ${got})"
  echo "Checksum OK"

  # Extract. The archive contains a single top dir: bynk-<version>-<target>/.
  rm -rf "$bindir"; mkdir -p "$bindir"
  case "$ext" in
    tar.gz) tar -xzf "${tmp}/${archive}" -C "$tmp" ;;
    zip)    unzip -q "${tmp}/${archive}" -d "$tmp" ;;
  esac
  # Flatten the inner dir into bindir.
  cp -R "${tmp}/${stem}/." "$bindir/"
  chmod +x "$bindir"/bynkc "$bindir"/bynk "$bindir"/bynkc-lsp 2>/dev/null || true
  rm -rf "$tmp"
  echo "Installed into ${bindir}"
}

cmd_activate() {
  local bindir="${RESOLVED_BINDIR:?}"
  echo "$bindir" >> "${GITHUB_PATH:?}"
  export PATH="${bindir}:${PATH}"
  echo "Bynk on PATH:"
  "${bindir}/bynkc" --version || die "bynkc failed to run after install"
}

case "${1:-}" in
  resolve)  cmd_resolve ;;
  download) cmd_download ;;
  activate) cmd_activate ;;
  *) die "unknown subcommand: ${1:-<none>}" ;;
esac
