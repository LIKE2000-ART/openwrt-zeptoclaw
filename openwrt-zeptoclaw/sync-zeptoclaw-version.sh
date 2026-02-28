#!/usr/bin/env bash
# dependent: curl jq
# Sync PKG_VERSION in Makefile with latest GitHub release tag.

set -euo pipefail

CURDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAKEFILE="$CURDIR/Makefile"
OWNER="qhkm"
REPO="zeptoclaw"
DRY_RUN=0

usage() {
	cat <<'EOF'
Usage:
  ./sync-zeptoclaw-version.sh [--dry-run]

Options:
  --dry-run   Print the target version without writing Makefile.
  -h, --help  Show this help.
EOF
}

github_get_latest_release() {
	curl -fsSL "https://api.github.com/repos/$OWNER/$REPO/releases/latest"
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--dry-run)
		DRY_RUN=1
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "Unknown argument: $1" >&2
		usage
		exit 2
		;;
	esac
done

if [[ ! -f "$MAKEFILE" ]]; then
	echo "Makefile not found: $MAKEFILE" >&2
	exit 1
fi

latest_info="$(github_get_latest_release)"
latest_tag="$(jq -r '.tag_name // empty' <<<"$latest_info")"
latest_version="${latest_tag#v}"

if [[ -z "$latest_version" ]]; then
	echo "Failed to parse latest release tag from GitHub API." >&2
	exit 1
fi

current_version="$(sed -n 's|^PKG_VERSION:=||p' "$MAKEFILE" | head -n1)"
if [[ -z "$current_version" ]]; then
	echo "Failed to parse PKG_VERSION from $MAKEFILE" >&2
	exit 1
fi

if [[ "$current_version" == "$latest_version" ]]; then
	echo "Already up to date: $current_version"
	exit 0
fi

echo "Current PKG_VERSION: $current_version"
echo "Latest  PKG_VERSION: $latest_version"

if [[ "$DRY_RUN" -eq 1 ]]; then
	echo "Dry-run mode; no file changes."
	exit 0
fi

tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

awk -v new_ver="$latest_version" '
	BEGIN { updated = 0 }
	/^PKG_VERSION:=/ {
		print "PKG_VERSION:=" new_ver
		updated = 1
		next
	}
	{ print }
	END {
		if (updated == 0) {
			exit 2
		}
	}
' "$MAKEFILE" >"$tmpfile"

mv "$tmpfile" "$MAKEFILE"
trap - EXIT

echo "Updated $MAKEFILE"
