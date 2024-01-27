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

check_install_type_is_version() {
	if [[ "$ASDF_INSTALL_TYPE" != "version" ]]; then
		echo "The AWFY plugin only supports version-based installations"
		echo "because it downloads binary releases."
		exit 1
	fi
}

curl_opts=(-fsSL)
curl_large_download_opts=(-fSL --progress-bar)

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
	eval "$cmd" 'https:///api.github.com/repos/oracle/graalpython/releases' |
		jq -r '.[] | select (.prerelease == false) | select (.tag_name | contains("graal-")) | select (.assets | length > 0) | .tag_name | ltrimstr("graal-")' |
		nl -bn -n ln -w1 -s 'graalpy-jvm-'
}

list_all_graaljs_versions() {
	if [ $# -eq 0 ]; then
		local type="all"
	else
		local type="$1"
	fi

	local cmd="curl -s"
	local release_json=$(eval "$cmd" 'https:///api.github.com/repos/oracle/graaljs/releases')

	if [[ "$type" != "jvm" ]]; then
		local versions=$(echo "$release_json" |
			jq -r '.[] | select (.prerelease == false) | select (.tag_name | contains("graal-")) | select (any(.assets[]; .name | contains("jvm") | not)) | .tag_name | ltrimstr("graal-")')
		echo "$versions" | nl -bn -n ln -w1 -s 'graaljs-'
	fi
	if [[ "$type" != "native" ]]; then
		local versions=$(echo "$release_json" |
			jq -r '.[] | select (.prerelease == false) | select (.tag_name | contains("graal-")) | select (any(.assets[]; .name | contains("jvm"))) | .tag_name | ltrimstr("graal-")')
		echo "$versions" | nl -bn -n ln -w1 -s 'graaljs-jvm-'
	fi
}

# jq -r '.[] | select (.tag_name == "graal-23.0.0") | .assets[] | select(.name | contains("jvm"))'

release_url_graaljs() {
	local version="$1"
	local kernel_name="$2"
	local arch="$3"
	local type="$4"

	local cmd="curl -s"

	local filter_for_version='select(.tag_name == "graal-'$version'")'
	local filter_for_graalnodejs='select(.name | contains("graalnodejs"))'

	if [[ "$kernel_name" == "darwin" ]]; then
		kernel_name="macos"
	fi

	local filter_for_os="select(.name | contains(\"$kernel_name\"))"

	if [[ "$arch" == "x86_64" ]]; then
		arch="amd64"
	elif [[ "$arch" == "arm64" ]]; then
		arch="aarch64"
	fi

	if [[ "$type" == "jvm" ]]; then
		local filter_for_type='select(.name | contains("-jvm-"))'
	else
		local filter_for_type='select(.name | contains("-jvm-") | not)'
	fi

	local filter_for_arch="select(.name | contains(\"$arch\"))"
	local filter_for_targz='select(.name | contains(".tar.gz"))'
	local discard_sha256='select(.name | contains(".sha256") | not)'
	local discard_community_edition='select(.name | contains("-community") | not)'

	local release_json=$(eval "$cmd" 'https:///api.github.com/repos/oracle/graaljs/releases')

	echo "$release_json" |
		jq -r ".[] | $filter_for_version | .assets[] |
	 		$filter_for_graalnodejs |
			$filter_for_os |
			$filter_for_arch |
			$filter_for_targz |
			$filter_for_type |
			$discard_sha256 |
			$discard_community_edition | .browser_download_url"
}

release_url_graalpy() {
	local version="$1"
	local kernel_name="$2"
	local arch="$3"
	local type="$4"

	local cmd="curl -s"

	local filter_for_version='select(.tag_name == "graal-'$version'")'

	if [[ "$kernel_name" == "darwin" ]]; then
		kernel_name="macos"
	fi

	local filter_for_os="select(.name | contains(\"$kernel_name\"))"

	if [[ "$arch" == "x86_64" ]]; then
		arch="amd64"
	elif [[ "$arch" == "arm64" ]]; then
		arch="aarch64"
	fi

	if [[ "$type" == "jvm" ]]; then
		local filter_for_type='select(.name | contains("-jvm-"))'
	else
		local filter_for_type='select(.name | contains("-jvm-") | not)'
	fi

	local filter_for_arch="select(.name | contains(\"$arch\"))"
	local filter_for_targz='select(.name | contains(".tar.gz"))'
	local discard_sha256='select(.name | contains(".sha256") | not)'
	local discard_community_edition='select(.name | contains("-community") | not)'

	local release_json=$(eval "$cmd" 'https:///api.github.com/repos/oracle/graalpython/releases')
	echo "$release_json" |
		jq -r ".[] | $filter_for_version | .assets[] |
			$filter_for_os |
			$filter_for_arch |
			$filter_for_targz |
			$filter_for_type |
			$discard_sha256 |
			$discard_community_edition | .browser_download_url"
}

download_release() {
	local url="$1"
	local filename="$2".tar.gz
	local version="$3"

	echo "* Downloading $version..."
	curl "${curl_large_download_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="$3"
	local download_targz=${ASDF_DOWNLOAD_PATH}.tar.gz

	if [ "$install_type" != "version" ]; then
		fail "The AWFY plugin supports version-based installations only."
	fi

	(
		mkdir -p "$install_path"
		tar -xzf "$download_targz" -C "$install_path" --strip-components=1
		echo "$version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $version."
	)
}
