#!/usr/bin/env bash
# dependent: curl jq git tar zstd
# Sync PKG_VERSION and PKG_MIRROR_HASH in Makefile with latest GitHub release tag.

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

sha256_file() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$1" | awk '{print $1}'
	else
		shasum -a 256 "$1" | awk '{print $1}'
	fi
}

replace_makefile_var() {
	local var="$1"
	local value="$2"
	local file="$3"
	local tmpfile

	tmpfile="$(mktemp)"
	trap 'rm -f "$tmpfile"' RETURN

	awk -v var="$var" -v value="$value" '
		BEGIN { updated = 0 }
		index($0, var ":=") == 1 {
			print var ":=" value
			updated = 1
			next
		}
		{ print }
		END {
			if (updated == 0) {
				exit 2
			}
		}
	' "$file" >"$tmpfile"

	mv "$tmpfile" "$file"
	trap - RETURN
}

build_openwrt_source_hash() {
	local tag="$1"
	local pkg_name="$2"
	local tmpdir repo_dir work_dir tar_git tar_zst tar_timestamp

	for cmd in git tar zstd; do
		command -v "$cmd" >/dev/null 2>&1 || {
			echo "Missing required command for hash generation: $cmd" >&2
			return 1
		}
	done

	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	repo_dir="$tmpdir/repo"
	work_dir="$tmpdir/work"
	tar_git="$tmpdir/${pkg_name}.tar.git"
	tar_zst="$tmpdir/${pkg_name}.tar.zst"

	git clone --depth 1 --branch "$tag" "https://github.com/$OWNER/$REPO.git" "$repo_dir" >/dev/null 2>&1
	tar_timestamp="$(git -C "$repo_dir" log -1 --format='@%ct')"

	git -C "$repo_dir" config core.abbrev 8
	git -C "$repo_dir" archive --format=tar HEAD --output="$tar_git"
	tar --numeric-owner --owner=0 --group=0 --ignore-failed-read -C "$repo_dir" -f "$tar_git" -r .git .gitmodules 2>/dev/null || true

	mkdir -p "$work_dir/$pkg_name"
	tar -C "$work_dir/$pkg_name" -xf "$tar_git"
	(
		cd "$work_dir/$pkg_name" || exit 1
		git submodule update --init --recursive -- >/dev/null 2>&1 || true
		rm -rf .git .gitmodules
	)

	tar --numeric-owner --owner=0 --group=0 --mode=a-s --sort=name \
		${tar_timestamp:+--mtime="$tar_timestamp"} \
		-c -C "$work_dir" "$pkg_name" | zstd -T0 --ultra -20 -c >"$tar_zst"

	sha256_file "$tar_zst"
	trap - RETURN
	rm -rf "$tmpdir"
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

replace_makefile_var "PKG_VERSION" "$latest_version" "$MAKEFILE"

pkg_name="openwrt-zeptoclaw-$latest_version"
echo "Generating PKG_MIRROR_HASH for $pkg_name (this may take a while)..."
new_hash="$(build_openwrt_source_hash "$latest_tag" "$pkg_name")"
if [[ -z "$new_hash" ]]; then
	echo "Failed to generate PKG_MIRROR_HASH" >&2
	exit 1
fi
replace_makefile_var "PKG_MIRROR_HASH" "$new_hash" "$MAKEFILE"

echo "Updated $MAKEFILE"
