#!/usr/bin/env bash

# This script is a wrapper for the q++ compiler, which transforms
# arguments passed to it. It replaces instances of -Xlinker with -Wl,
# and handles response files (files starting with @) by creating a new
# response file with the transformed arguments.
# We do all of this because bazel's cc_import and cc_shared_library rules
# implicitly add -Xlinker to the command line, and there is no working around it

set -Eeuo pipefail

declare -a second_pass_args

function transform_args() {
	local i=1
	while [[ ${i} -le $# ]]; do
		echo "${!i}"
		if [[ ${!i} == "-Xlinker" && $((i + 1)) -lt $# ]]; then
			((i++))
			next_arg="${!i}"
			((i++))
			while [[ ${!i} == "-Xlinker" && $((i + 1)) -lt $# ]]; do
				((i++))
				next_arg+=",${!i}"
				((i++))
			done
			second_pass_args+=("-Wl,${next_arg}")
		else
			second_pass_args+=("${!i}")
			((i++))
		fi
	done
}

# Process response file (@filename)
function transform_response_file() {
	local file="${1:1}" # remove @
	local new_file="${file%.*}_qcc.params"
	local transformed=()
	local xlinker_found=false
	while IFS= read -r line || [[ -n ${line} ]]; do
		if [[ ${line} == "-Xlinker" ]]; then
			read -r next_line
			next_arg="${next_line}"
			if [[ ${xlinker_found} == true ]]; then
				# Get the index of the last element
				last_index=$((${#transformed[@]} - 1))

				# Change the last element
				transformed[last_index]="${transformed[last_index]},${next_arg}"
			else
				transformed+=("-Wl,${next_arg}")
			fi
			xlinker_found=true
		else
			xlinker_found=false
			transformed+=("${line}")
		fi
	done <"${file}"
	printf "%s\n" "${transformed[@]}" >"${new_file}"
	echo "@${new_file}"
}

first_pass_args=()
for arg in "$@"; do
	if [[ ${arg} == @* ]]; then
		first_pass_args+=("$(transform_response_file "${arg}")")
	else
		first_pass_args+=("${arg}")
	fi
done

# Apply the -Xlinker replacement to non-response file args
transform_args "${first_pass_args[@]}"

# Call the real q++
exec "$(dirname "$0")/q++" "${second_pass_args[@]}"
