#!/bin/bash

# Copyright (c) Sid Menon 2026
# Modifications by : Sid Menon (sidgmenon@gmail.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Build script for custom toolchain (with its own sysroot)
#
# This script builds two outputs:
# 1. Sysroot tarball: toolchain-gcc{version}-{arch}.tar.xz
# 2. Cross-compiler: {arch}--glibc--custom-gcc{version}-{date}.tar.xz
#
# Usage: ./build.sh <arch> <output_dir> [gcc_version]
# Example: ./build.sh aarch64 /tmp/output 13.4.0

readonly arch=$1
readonly output_dir=$2
readonly variant=$3
readonly gcc_version=${4-}

set -euo errexit -o nounset -o pipefail

if [[ -z ${arch} ]]; then
	echo >&2 "ERROR: the first argument of the script must be the architecture."
	exit 1
fi

if [[ -z ${output_dir} ]]; then
	echo >&2 "ERROR: the second argument of the script must be the output directory."
	exit 1
fi

if [[ -z ${variant} ]]; then
	echo >&2 "ERROR: the third argument of the script must be the variant (base or X11)."
	exit 1
fi

extra_build_args=""
if [[ -n ${gcc_version} ]]; then
	# Map GCC versions to glibc/kernel versions (aligning with Dockerfile logic)
	case "${gcc_version}" in
	"13.4.0")
		#lines up with Yocto Scarthgap (approximately coincides with Ubuntu 24.04)
		GLIBC_GIT_COMMIT=198632a05f6c7b9ab67d3331d8caace9ceabb685 #2.39
		KERNEL_VERSION="6.6"
		;;
	"11.3.0")
		#lines up with Yocto Kirkstone (approximately coincides with Ubuntu 22.04)
		GLIBC_GIT_COMMIT=b6aade18a7e5719c942aa2da6cf3157aca993fa4 #2.35
		KERNEL_VERSION="5.15"
		;;
	"8.4.0")
		#lines up with Ubuntu 18.04
		GLIBC_GIT_COMMIT=00cdcf5a4110f7ac68651f5662693c82f7bffaca #2.26
		KERNEL_VERSION="4.9"
		;;
	*)
		echo >&2 "ERROR: the fourth argument of the script must be one of the following GCC versions: 13.4.0, 11.3.0, 8.4.0."
		exit 1
		;;
	esac
	extra_build_args+="--build-arg GCC_VERSION=${gcc_version} "
	extra_build_args+="--build-arg GLIBC_GIT_COMMIT=${GLIBC_GIT_COMMIT} "
	extra_build_args+="--build-arg KERNEL_VERSION=${KERNEL_VERSION} "
else
	gcc_version="13.4.0"
fi

echo "INFO: building toolchain inside container..."
sysroot_dir="$(git rev-parse --show-toplevel)/sysroot"
sysroot_output="$(realpath "${output_dir}")/toolchain-${variant}-gcc${gcc_version}-${arch}.tar.xz"
image_tag=$(tr '[:upper:]' '[:lower:]' <<<"toolchain-${variant}-gcc${gcc_version}-${arch}")

(
	cd "${sysroot_dir}"
	# shellcheck disable=SC2086
	docker build \
		--network=host \
		--build-arg http_proxy="${http_proxy-}" \
		--build-arg https_proxy="${http_proxy-}" \
		--build-arg no_proxy="${no_proxy-}" \
		--build-arg ARCH="${arch}" \
		${extra_build_args} \
		--tag "${image_tag}" \
		--target "toolchain_${variant}" \
		.
)
echo "INFO: exporting sysroot to '${sysroot_output}'..."

tmpdir="$(mktemp -d)"
container_id=""

function cleanup_all {
	echo "INFO: Cleaning up..."
	if [[ -n ${container_id} ]]; then
		echo "INFO: Removing sysroot container..."
		docker rm "${container_id}" >/dev/null 2>&1 || true
	fi
	if [[ -n ${tmpdir} && -d ${tmpdir} ]]; then
		echo "INFO: Removing temp directory..."
		rm -rf "${tmpdir}"
	fi
}
trap cleanup_all EXIT

# Export sysroot
echo "INFO: Creating sysroot container..."
if ! container_id="$(docker create "${image_tag}")"; then
	echo >&2 "ERROR: Failed to create sysroot container"
	exit 1
fi

echo "INFO: Extracting sysroot from container..."
if ! docker cp "${container_id}:/var/builds/toolchain-${variant}-${arch}.tar.xz" "${sysroot_output}"; then
	echo >&2 "ERROR: Failed to extract sysroot from container"
	exit 1
fi
echo "INFO: Sysroot created:"
shasum -a 256 "${sysroot_output}"
