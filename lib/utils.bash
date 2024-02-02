#!/usr/bin/env bash

set -euo pipefail

TOOL_NAME="awfy"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

prefix_version_list() {
	local prefix="$1"
	local versions="$2"
	local version
	for version in $versions; do
		echo "$prefix$version"
	done
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

list_all_versions() {
	list_all_graalpyjvm_versions
	list_all_graaljs_versions "all"
	list_all_pharo_versions
	list_all_squeak_versions
}

list_all_pharo_versions() {
	local cmd="curl -s"
	local versions_html versions
	versions_html=$(eval "$cmd" 'https://files.pharo.org/get-files/')
	versions=$(echo "$versions_html" | grep -o '<a href="[^"]*"' | grep -o -E '[0-9]+' | sort -n)
	prefix_version_list 'pharo-' "$versions"
}

get_arch_bits() {
	if [[ "$(uname -m)" == *"64"* ]]; then
		echo "64"
	else
		echo "32"
	fi
}

list_all_squeak_versions() {
	local arch_bits
	arch_bits=$(get_arch_bits)
	local cmd="curl -s"
	local versions_html versions release_urls releases
	versions_html=$(eval "$cmd" 'https://files.squeak.org/')
	versions=$(echo "$versions_html" |
		grep -o '<a href="[^"]*"' |
		grep -o -E '[0-9]+\.[0-9]+/' |
		grep -o -E '[0-9]+\.[0-9]+')

	release_urls=""
	for version in $versions; do
		release_urls="$release_urls https://files.squeak.org/$version/"
	done

	releases=$(eval "$cmd" "$release_urls" |
		grep -o '>Squeak[^/]*/' |
		grep -o 'Squeak[^<]*' |
		grep "${arch_bits}bit")

	for release in $releases; do
		local v r
		v=$(echo "$release" | grep -o -E '[0-9]+\.[0-9]+')
		r=$(echo "$release" | grep -o -E '[0-9][0-9][0-9]+')
		echo "squeak-$v-$r"
	done
}

list_all_graalpyjvm_versions() {
	local cmd="curl -s"
	local versions
	versions=$(eval "$cmd" 'https://api.github.com/repos/oracle/graalpython/releases' |
		jq -r '.[] | select (.prerelease == false) | select (.tag_name | contains("graal-")) | select (.assets | length > 0) | .tag_name | ltrimstr("graal-")')
	prefix_version_list 'graalpy-jvm-' "$versions"
}

list_all_graaljs_versions() {
	if [ $# -eq 0 ]; then
		local type="all"
	else
		local type="$1"
	fi

	local cmd="curl -s"
	local release_json versions
	release_json=$(eval "$cmd" 'https://api.github.com/repos/oracle/graaljs/releases')

	if [[ "$type" != "jvm" ]]; then
		versions=$(echo "$release_json" |
			jq -r '.[] | select (.prerelease == false) | select (.tag_name | contains("graal-")) | select (any(.assets[]; .name | contains("jvm") | not)) | .tag_name | ltrimstr("graal-")')
		prefix_version_list 'graaljs-' "$versions"
	fi
	if [[ "$type" != "native" ]]; then

		versions=$(echo "$release_json" |
			jq -r '.[] | select (.prerelease == false) | select (.tag_name | contains("graal-")) | select (any(.assets[]; .name | contains("jvm"))) | .tag_name | ltrimstr("graal-")')
		prefix_version_list 'graaljs-jvm-' "$versions"
	fi
}

get_jq_filter_for_os() {
	local kernel_name
	kernel_name=$(uname -s | tr '[:upper:]' '[:lower:]')
	if [[ "$kernel_name" == "darwin" ]]; then
		kernel_name="macos"
	fi
	echo "select(.name | contains(\"$kernel_name\"))"
}

get_jq_filter_for_arch() {
	local arch
	arch=$(uname -m)
	if [[ "$arch" == "x86_64" ]]; then
		arch="amd64"
	elif [[ "$arch" == "arm64" ]]; then
		arch="aarch64"
	fi
	echo "select(.name | contains(\"$arch\"))"
}

get_jq_filter_for_vm_type() {
	local type="$1"
	if [[ "$type" == "jvm" ]]; then
		echo "select(.name | contains(\"-jvm-\"))"
	else
		echo "select(.name | contains(\"-jvm-\") | not)"
	fi
}

release_url_graaljs() {
	local version="$1"
	local type="$2"
	local filter_for_graalnodejs='select(.name | contains("graalnodejs"))'
	release_url_graal_projects "$version" "oracle/graaljs" "$type" "$filter_for_graalnodejs"
}

release_url_graalpy() {
	local version="$1"
	local type="$2"
	release_url_graal_projects "$version" "oracle/graalpython" "$type"
}

download_pharo() {
	local version="$1"
	echo "Downloading Pharo $version"

	mkdir -p "$ASDF_DOWNLOAD_PATH"

	(cd "$ASDF_DOWNLOAD_PATH" && curl "${curl_opts[@]}" "https://get.pharo.org/$version" | bash)
	(cd "$ASDF_DOWNLOAD_PATH" && curl "${curl_opts[@]}" "https://get.pharo.org/vm$version" | bash)
	exit 0
}

get_squeak_os_name() {
	local os_name
	os_name=$(uname -s)
	if [[ "$os_name" == "Darwin" ]]; then
		os_name="macOS"
	fi
	echo "$os_name"
}

get_squeak_arch() {
	local arch
	arch=$(uname -m)
	if [[ "$arch" == "x86_64" ]]; then
		arch="x64"
	elif [[ "$arch" == "arm64" ]]; then
		arch="ARMv8"
	fi
	echo "$arch"
}

release_url_squeak() {
	local version="$1"

	local cmd="curl -s"
	local arch_bits release_folder_url release_file v r os_name arch
	v=$(echo "$version" | cut -d- -f1)
	r=$(echo "$version" | cut -d- -f2)
	arch_bits=$(get_arch_bits)
	os_name=$(get_squeak_os_name)
	arch=$(get_squeak_arch)

	release_folder_url="https://files.squeak.org/$v/Squeak$version-${arch_bits}bit/"

	content=$(eval "$cmd" "$release_folder_url")
	release_file=$(eval "$cmd" "$release_folder_url" |
		grep -o -E "Squeak$version-${arch_bits}bit-[0-9]+-$os_name-$arch.[^\"<]+\"")
	rf_length=${#release_file}
	release_file=${release_file:0:rf_length-1}
	echo "https://files.squeak.org/$v/Squeak$version-${arch_bits}bit/$release_file"
}

release_url_graal_projects() {
	local version="$1"
	local project="$2"
	local type="$3"

	if [[ "$#" -eq 3 ]]; then
		local additional_filter="."
	else
		local additional_filter="$4"
	fi

	local filter_for_version='select(.tag_name == "graal-'$version'")'
	local filter_for_os filter_for_os filter_for_type
	filter_for_os=$(get_jq_filter_for_os)
	filter_for_arch=$(get_jq_filter_for_arch)
	filter_for_type=$(get_jq_filter_for_vm_type "$type")

	local filter_for_targz='select(.name | contains(".tar.gz"))'
	local discard_sha256='select(.name | contains(".sha256") | not)'
	local discard_community_edition='select(.name | contains("-community") | not)'

	local cmd="curl -s"
	local release_json
	release_json=$(eval "$cmd" "https://api.github.com/repos/$project/releases")

	echo "$release_json" |
		jq -r ".[] | $filter_for_version | .assets[] |
			$additional_filter |
			$filter_for_os |
			$filter_for_arch |
			$filter_for_targz |
			$filter_for_type |
			$discard_sha256 |
			$discard_community_edition | .browser_download_url"
}

download_release() {
	local url="$1"
	local filename="$2"
	local version="$3"

	echo "* Downloading $version..."
	curl "${curl_large_download_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="$3"

	if [ "$install_type" != "version" ]; then
		fail "The AWFY plugin supports version-based installations only."
	fi

	if [[ "$version" == "pharo"* ]]; then
		mv "$ASDF_DOWNLOAD_PATH" "$install_path/../"
	else
		local download_targz=${ASDF_DOWNLOAD_PATH}.tar.gz
		local download_dmg=${ASDF_DOWNLOAD_PATH}.dmg
		(
			mkdir -p "$install_path"
			if [[ -f "$download_targz" ]]; then
				tar -xzf "$download_targz" -C "$install_path" --strip-components=1
			elif [[ -f "$download_dmg" ]]; then
				local mount_point
				mount_point=$(hdiutil attach "$download_dmg" | grep Volumes | cut -f3)

				if [[ "$version" == "squeak"* ]]; then
					# Squeak is distributed as a .app bundle
					cp -R "$mount_point"/*.app "$install_path/Squeak.app"
				else
					cp -R "$mount_point"/* "$install_path"
				fi

				hdiutil detach "$mount_point"
			else
				fail "Could not find downloaded file for $version"
			fi
			echo "$version installation was successful!"
		) || (
			rm -rf "$install_path"
			fail "An error occurred while installing $version."
		)
	fi
}
