#!/usr/bin/env bash
set -euo pipefail

REPO=arnavsx3/warpctl
VERSION=${WARPCTL_VERSION:-v1.0.0}
DEST=${WARPCTL_DEST:-$HOME/.local/bin}
SELF_DIR=
# When piped (`curl ... | bash`) there is no script path, so skip the local-checkout mode.
if [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]]; then
    SELF_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fi

die() {
    printf 'install: %s\n' "$1" >&2
    exit 1
}

if ((EUID == 0)); then
    die 'do not run as root; install per-user, no sudo needed.'
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

if [[ -n $SELF_DIR && -f $SELF_DIR/warpctl ]]; then
    src=$SELF_DIR/warpctl
    printf 'Installing from local checkout: %s\n' "$src"
else
    command -v curl >/dev/null 2>&1 || die 'curl is required.'
    url="https://raw.githubusercontent.com/$REPO/$VERSION/warpctl"
    printf 'Fetching %s\n' "$url"
    curl -fsSL "$url" -o "$tmp" || die "download failed: $url"
    src=$tmp
fi

[[ $(head -n1 "$src") == '#!/usr/bin/env bash' ]] ||
    die 'downloaded file is not the warpctl script.'
bash -n "$src" || die 'script failed a syntax check; aborting.'

mkdir -p "$DEST"
install -m 755 "$src" "$DEST/warpctl"

printf '\nInstalled %s\n' "$DEST/warpctl"
printf 'SHA256 %s\n' "$(sha256sum "$DEST/warpctl" | cut -d' ' -f1)"

case ":$PATH:" in
    *":$DEST:"*) ;;
    *)
        printf '\nNote: %s is not on your PATH. Add it to your shell profile.\n' "$DEST"
        ;;
esac

if [[ $VERSION == main && $src == "$tmp" ]]; then
    printf '\nNote: installed from main, not a release tag. Set WARPCTL_VERSION=v1.0.0 to pin.\n'
fi

printf '\nNext: warpctl status\n'
