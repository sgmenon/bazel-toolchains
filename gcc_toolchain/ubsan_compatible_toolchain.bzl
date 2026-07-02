# Copyright (c) Sid Menon 2026
# Original Author: Sid Menon (sidgmenon@gmail.com)
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

"""UBSan-compatible toolchain configuration for gRPC dependencies."""

load("//toolchains/gcc_toolchain:cc_toolchain_config.bzl", "cc_toolchain_config")

def ubsan_compatible_toolchain_config(
        ctx,
        cpu,
        compiler,
        toolchain_identifier,
        host_system_name,
        target_system_name,
        target_libc,
        abi_version,
        abi_libc_version,
        cc_target_os,
        builtin_sysroot,
        extra_cflags = [],
        extra_cxxflags = [],
        extra_fflags = [],
        extra_ldflags = [],
        extra_defines = [],
        extra_includes = [],
        gcc_toolchain_path = None,
        gcc_sysroot = None):
    """Creates a cc_toolchain_config with UBSan flags modified for gRPC compatibility."""

    # Add -fno-sanitize=vptr to extra_cxxflags when UBSan is enabled
    modified_extra_cxxflags = extra_cxxflags + [
        "-fno-sanitize=vptr",  # Disable vptr sanitizer for gRPC compatibility
    ]

    return cc_toolchain_config(
        ctx = ctx,
        cpu = cpu,
        compiler = compiler,
        toolchain_identifier = toolchain_identifier,
        host_system_name = host_system_name,
        target_system_name = target_system_name,
        target_libc = target_libc,
        abi_version = abi_version,
        abi_libc_version = abi_libc_version,
        cc_target_os = cc_target_os,
        builtin_sysroot = builtin_sysroot,
        extra_cflags = extra_cflags,
        extra_cxxflags = modified_extra_cxxflags,
        extra_fflags = extra_fflags,
        extra_ldflags = extra_ldflags,
        extra_defines = extra_defines,
        extra_includes = extra_includes,
        gcc_toolchain_path = gcc_toolchain_path,
        gcc_sysroot = gcc_sysroot,
    )
