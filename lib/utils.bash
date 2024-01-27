#!/usr/bin/env bash

set -euo pipefail

# TODO: Ensure this is the correct GitHub homepage where releases can be downloaded for awfy.
GH_REPO="https://github.com/smarr/are-we-fast-yet"
TOOL_NAME="awfy"
TOOL_TEST="awfy --version"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if awfy is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' | cut -d/ -f3- |
		sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
	list_all_graalpyjvm_versions
	list_all_graaljs_versions
}

list_all_graalpyjvm_versions() {
	cmd="curl -s"
	eval "$cmd" 'https:///api.github.com/repos/oracle/graalpython/releases' | \
		jq -r 'sort_by(.created_at) | .[] | select (.prerelease == false) | select (.tag_name | contains("graal-")) | select (.assets | length > 0) | .tag_name | ltrimstr("graal-")' | \
		nl -bn -n ln -w1 -s 'graalpy-jvm-'
}

list_all_graaljs_versions() {
	cmd="curl -s"
	versions=$(eval "$cmd" 'https:///api.github.com/repos/oracle/graaljs/releases' | \
		jq -r 'sort_by(.created_at) | .[] | select (.prerelease == false) | select (.tag_name | contains("graal-")) | select (.assets | length > 0) | .tag_name | ltrimstr("graal-")')
	echo "$versions" | nl -bn -n ln -w1 -s 'graaljs-'
	echo "$versions" | nl -bn -n ln -w1 -s 'graaljs-jvm-'
}

download_release() {
	local version filename url
	version="$1"
	filename="$2"

	# TODO: Adapt the release URL convention for awfy
	url="$GH_REPO/archive/v${version}.tar.gz"

	echo "* Downloading $TOOL_NAME release $version..."
	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}/bin"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"
		cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

		# TODO: Assert awfy executable exists.
		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
