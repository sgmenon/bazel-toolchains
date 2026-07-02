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

load("@rules_cc//cc:defs.bzl", "cc_toolchain", "cc_library")
load("@%toolchain_workspace_name%//%path_to_toolchain_files%:cc_toolchain_config.bzl", "cc_toolchain_config")
load("@%toolchain_workspace_name%//%path_to_toolchain_files%/fortran:defs.bzl", "fortran_toolchain")
load("//:tool_paths.bzl", "tool_paths")

package(default_visibility = ["//visibility:public"])

toolchain(
    name = "fortran_toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = %target_compatible_with%,
    toolchain = ":_fortran_toolchain",
    toolchain_type = "@%toolchain_workspace_name%//%path_to_toolchain_files%/fortran:toolchain_type",
)

fortran_toolchain(
    name = "_fortran_toolchain",
    cc_toolchain = ":_cc_toolchain",
)

toolchain(
    name = "cc_toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = %target_compatible_with%,
    target_settings = %target_settings%,
    toolchain = ":_cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

cc_toolchain(
    name = "_cc_toolchain",
    all_files = ":all_files",
    ar_files = ":ar_files",
    as_files = ":as_files",
    compiler_files = ":compiler_files",
    dwp_files = ":dwp_files",
    linker_files = ":linker_files",
    objcopy_files = ":objcopy_files",
    strip_files = ":strip_files",
    coverage_files = ":coverage_files",
    supports_param_files = 0,
    toolchain_config = ":cc_toolchain_config",
    toolchain_identifier = "gcc-toolchain",
)

cc_toolchain_config(
    name = "cc_toolchain_config",
    builtin_sysroot = "%sysroot%",
    compiler_version = "%compiler_version%",
    cxx_builtin_include_directories = %cxx_builtin_include_directories%,
    extra_cflags = %extra_cflags%,
    extra_cxxflags = %extra_cxxflags%,
    extra_fflags = %extra_fflags%,
    extra_ldflags = %extra_ldflags%,
    extra_asmflags = %extra_asmflags%,
    tool_paths = tool_paths,
)

filegroup(
    name = "all_files",
    srcs = [
        ":ar_files",
        ":as_files",
        ":compiler_files",
        ":coverage_files",
        ":dwp_files",
        ":linker_files",
        ":objcopy_files",
        ":strip_files",
    ],
)

filegroup(
    name = "_sysroot_files",
    srcs = glob(["sysroot/**"])
)

filegroup(
    name = "compiler_files",
    srcs = [
        ":as_files",
        ":gcc",
        ":include",
        ":_sysroot_files",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "linker_files",
    srcs = [
        ":ar",
        ":gcc",
        ":lib",
        ":ld_files",
        ":_sysroot_files",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "ld_files",
    srcs = [
        ":ld",
        ":ld.bfd",
        "xbin/ld",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "include",
    srcs = glob([
        # C includes
        "lib/gcc/%include_prefix%*/include/**",
        "lib/gcc/%include_prefix%*/include-fixed/**",
        "%include_prefix%include/**",
        "sysroot/usr/include/**",

        # C++ includes
        "%include_prefix%include/c++/*/**",
        "include/c++/*/**",
        "%include_prefix%include/c++/*/backward/**",
        "include/c++/*/backward/**",

        # Fortran includes
        "lib/gcc/%include_prefix%*/finclude/**",
    ], allow_empty=True),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "lib",
    srcs = glob(
        include = [
            "**/*.so",
            "**/*.so.*",
            "**/*.a",
            "**/*.la",
            "**/*.o",
            "**/*.lo",
        ],
        exclude = ["lib*/**/*python*/**"],
        allow_empty = True,
    ),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "gcc",
    srcs = [
        "bin/%binary_prefix%cpp",
        "bin/%binary_prefix%g++",
        "bin/%binary_prefix%gcc",
        "bin/%binary_prefix%gfortran",
        "xbin/cpp",
        "xbin/g++",
        "xbin/gcc",
        "xbin/gfortran",
    ] + glob([
        "**/libexec/gcc/**/cc1plus",
        "**/libexec/gcc/**/cc1",
        "**/libexec/gcc/**/f951",
        # These shared objects are needed at runtime by GCC when linked dynamically to them.
        "lib/libgmp.so*",
        "lib/libmpc.so*",
        "lib/libmpfr.so*",
        # Fortran spec files.
        "**/lib*/libgfortran.spec",
        "**/lib*/libgomp.spec",
    ], allow_empty=True),
    visibility = ["//visibility:public"],
)

# Binutils

filegroup(
    name = "ar_files",
    srcs = [
        ":ar",
        "xbin/ar",
        ":_sysroot_files",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "as_files",
    srcs = [
        ":as",
        "xbin/as",
        ":gcc",
        ":_sysroot_files",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "dwp_files",
    srcs = [],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "objcopy_files",
    srcs = [
        ":objcopy",
        "xbin/objcopy",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "strip_files",
    srcs = [
        ":strip",
        "xbin/strip",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "coverage_files",
    srcs = [
        ":gcov",
        "xbin/gcov",
    ],
    visibility = ["//visibility:public"],
)

[
    filegroup(
        name = bin,
        srcs = [
            "bin/%binary_prefix%" + bin,
        ],
        visibility = ["//visibility:public"],
    )
    for bin in [
        "ar",
        "as",
        "gcov",
        "ld",
        "ld.bfd",
        "nm",
        "objcopy",
        "objdump",
        "ranlib",
        "readelf",
        "strip",
    ]
]

cc_library(
    name = "libstdcxx",
    srcs = glob(
        include = ["**/libstdc++.so*"],
        exclude = ["**/*.py"],
    ),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "libstdcxx_static",
    srcs = glob(["**/libstdc++.a"]),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "libasan",
    srcs = glob([
        "lib*/libasan.so*",
    ], allow_empty=True),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "liblsan",
    srcs = glob([
        "lib*/liblsan.so*",
    ], allow_empty=True),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "libtsan",
    srcs = glob([
        "lib*/libtsan.so*",
    ], allow_empty=True),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "libubsan",
    srcs = glob([
        "lib*/libubsan.so*",
    ], allow_empty=True),
    visibility = ["//visibility:public"],
)