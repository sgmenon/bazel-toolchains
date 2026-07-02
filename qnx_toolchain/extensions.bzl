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
"""Extension for using the toolchain in a BZLMOD module"""

load("//qnx_toolchain/toolchains:rules.bzl", "ifs_toolchain", "qcc_toolchain")

def _impl(mctx):
    for mod in mctx.modules:
        if not mod.is_root:
            fail("Only the root module can use the 'toolchains_qnx' extension")

        for sdp in mod.tags.sdp:
            name = sdp.name
            url = sdp.url
            sha256 = sdp.sha256
            strip_prefix = sdp.strip_prefix
            for arch in sdp.arch:
                # Register the toolchains
                qcc_toolchain(
                    name = "%s_%s" % (name, arch),
                    url = url,
                    sha256 = sha256,
                    strip_prefix = strip_prefix,
                    arch = arch,
                    qcc_version = sdp.qcc_version,
                    qnx_version = sdp.qnx_version,
                    qnx_license_path = sdp.qnx_license_path,
                )

                ifs_toolchain(
                    name = "%s_%s_ifs" % (name, arch),
                    arch = arch,
                    toolchain_repo_name = sdp.toolchain_module_name,
                )

toolchains_qnx = module_extension(
    implementation = _impl,
    tag_classes = {
        "sdp": tag_class(
            attrs = {
                "arch": attr.string_list(mandatory = True),
                "name": attr.string(default = "toolchains_qnx"),
                "qnx_license_path": attr.label(allow_single_file = True, mandatory = True),
                "sha256": attr.string(mandatory = True),
                "strip_prefix": attr.string(default = ""),
                "qcc_version": attr.string(mandatory = True),
                "qnx_version": attr.string(mandatory = True),
                "toolchain_module_name": attr.string(default = "bazel-toolchains"),
                "url": attr.string(mandatory = True),
            },
        ),
    },
)
