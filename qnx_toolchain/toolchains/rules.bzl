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
"""Repository rules for registring a QCC toolchain and an IFS toolchain"""

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "get_auth")

TOOL_PATH_MAP = {
    "ar": "ar",
    "cpp": "qpp",
    "gcc": "qcc",
    "ld": "qpp_wrapper",
    "nm": "nm",
    "objcopy": "objcopy",
    "objdump": "objdump",
    "strip": "strip",
}

def _make_tool_invoker(rctx, tool_name):
    if rctx.attr.arch == "x86_64":
        abi = "pc"
    else:
        abi = "unknown"
    rctx.file("bin/{tool_name}".format(tool_name = tool_name), """/usr/bin/env sh
set -e
external/{repo_name}/sdp/host/linux/x86_64/usr/bin/{arch}-{abi}-nto-qnx{qnx_version}-{tool_name} "$@"
""".format(
        repo_name = rctx.name,
        arch = rctx.attr.arch,
        abi = abi,
        qnx_version = rctx.attr.qnx_version,
        tool_name = tool_name,
    ))

def _qcc_toolchain_impl(rctx):
    rctx.download_and_extract(
        url = [rctx.attr.url],
        sha256 = rctx.attr.sha256,
        strip_prefix = rctx.attr.strip_prefix,
        auth = get_auth(rctx, [rctx.attr.url]),
        output = "sdp",
    )
    if rctx.attr.arch == "x86_64":
        abi = "pc"
    else:
        abi = "unknown"
    rctx.template(
        "sdp/BUILD.bazel",
        Label("//qnx_toolchain/toolchains:sdp.BUILD"),
        substitutions = {
            "%{abi}": abi,
            "%{arch}": rctx.attr.arch,
            "%{qcc_version}": rctx.attr.qcc_version,
            "%{qnx_version}": rctx.attr.qnx_version,
        },
    )
    rctx.template(
        "sdp/host/linux/x86_64/usr/bin/qpp_wrapper.sh",
        Label("//qnx_toolchain/toolchains:qpp_wrapper.sh"),
        executable = True,
        substitutions = {},
    )

    # Create a symlink to the QNX license path so it can be relative to the build folder
    rctx.symlink(rctx.path(rctx.attr.qnx_license_path), "sdp/host/linux/x86_64/.qnx")

    rctx.template(
        "BUILD",
        rctx.attr._cc_toolchain_build,
        {
            "%{arch}": rctx.attr.arch,
        },
    )

    if rctx.attr.arch == "aarch64":
        # who still uses big endian?
        ntoarch = rctx.attr.arch + "le"
        platform_definitions = "-D__ARM_NEON__"
    else:
        ntoarch = rctx.attr.arch

        # this is a junk definition - we don't really use it
        platform_definitions = "-D__x86_64__"

    rctx.template(
        "cc_toolchain_config.bzl",
        rctx.attr._cc_toolchain_config_bzl,
        {
            "%{arch}": rctx.attr.arch,
            "%{ntoarch}": ntoarch,
            "%{platform_definitions}": platform_definitions,
        },
    )

    for tool_name in TOOL_PATH_MAP.keys():
        _make_tool_invoker(rctx, tool_name)

    rctx.file("tool_paths.bzl", "tool_paths = {}".format({
        tool: "bin/{target_path}".format(
            target_path = target_path,
        )
        for tool, target_path in TOOL_PATH_MAP.items()
    }))

qcc_toolchain = repository_rule(
    implementation = _qcc_toolchain_impl,
    attrs = {
        "arch": attr.string(mandatory = True),
        "qcc_version": attr.string(mandatory = True),
        "qnx_license_path": attr.label(allow_single_file = True, mandatory = True),
        "qnx_version": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "strip_prefix": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
        "_cc_toolchain_build": attr.label(
            default = "//qnx_toolchain/toolchains/qcc:toolchain.BUILD",
        ),
        "_cc_toolchain_config_bzl": attr.label(
            default = "//qnx_toolchain/toolchains/qcc:cc_toolchain_config.bzl",
        ),
    },
)

def _ifs_toolchain_impl(rctx):
    rctx.template(
        "BUILD",
        rctx.attr._ifs_toolchain_build,
        {
            "%{arch}": rctx.attr.arch,
            "%{toolchain_repo_name}": rctx.attr.toolchain_repo_name,
        },
    )

ifs_toolchain = repository_rule(
    implementation = _ifs_toolchain_impl,
    attrs = {
        "arch": attr.string(mandatory = True),
        "toolchain_repo_name": attr.string(mandatory = True),
        "_ifs_toolchain_build": attr.label(
            default = "//qnx_toolchain/toolchains/fs/ifs:ifs.BUILD",
        ),
    },
)
