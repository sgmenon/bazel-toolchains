load("@rules_cc//cc/toolchains:cc_toolchain.bzl", "cc_toolchain")
load("//:tool_paths.bzl", "tool_paths")

# *******************************************************************************
# Copyright (c) 2025 Contributors to the Eclipse Foundation
#
# See the NOTICE file(s) distributed with this work for additional
# information regarding copyright ownership.
#
# This program and the accompanying materials are made available under the
# terms of the Apache License Version 2.0 which is available at
# https://www.apache.org/licenses/LICENSE-2.0
#
# SPDX-License-Identifier: Apache-2.0
# *******************************************************************************
load(":cc_toolchain_config.bzl", "cc_toolchain_config")

filegroup(
    name = "all_files",
    srcs = [
        ":tools",  #symlink to sdp created by the repository rule
        "//sdp:all_files",
    ],
)

# These are essentially files that invoke the respective tool from the SDP repo
# The reason we have these symlinks is because bazel's tool_paths (used for enabling certain toolchain features)
# only supports paths relative to the toolchain's repository and symlinks to other repositories raise warnings
# (rightfully so).
filegroup(
    name = "tools",
    srcs = glob([
        "bin/*",
    ]),
    visibility = ["//visibility:public"],
)

[
    filegroup(
        name = bin,
        srcs = [
            "//sdp:" + bin,
        ],
        visibility = ["//visibility:public"],
    )
    for bin in [
        "ar",
        "objcopy",
    ]
]

filegroup(
    name = "empty",
)

cc_toolchain_config(
    name = "qcc_toolchain_config",
    ar_binary = "//sdp:ar",
    cc_binary = "//sdp:qcc",
    cxx_binary = "//sdp:qpp",
    cxx_builtin_include_directories = "//sdp:cxx_builtin_include_directories",
    ld_binary = "//sdp:qpp_wrapper",
    objcopy_binary = "//sdp:objcopy",
    qnx_host = "//sdp:host_dir",
    qnx_license_path = "//sdp:license",
    qnx_target = "//sdp:target_dir",
    strip_binary = "//sdp:strip",
    tool_paths = tool_paths,
)

cc_toolchain(
    name = "qcc_toolchain",
    all_files = ":all_files",
    ar_files = ":all_files",
    as_files = ":all_files",
    compiler_files = ":all_files",
    dwp_files = ":empty",
    linker_files = ":all_files",
    objcopy_files = ":all_files",
    strip_files = ":all_files",
    toolchain_config = ":qcc_toolchain_config",
)

toolchain(
    name = "qcc",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    target_compatible_with = [
        "@platforms//cpu:%{arch}",
        "@platforms//os:qnx",
    ],
    toolchain = ":qcc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    visibility = [
        "//:__pkg__",
    ],
)
