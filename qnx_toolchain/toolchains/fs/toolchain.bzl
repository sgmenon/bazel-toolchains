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
"""
Toolchain provider implementation for QNX filesystem image rules.
"""

ToolInfo = provider(
    doc = "Executable for generating QNX filesystems.",
    fields = ["executable", "files", "env"],
)

def _impl(ctx):
    env = {
        "PATH": "/proc/self/cwd/" + ctx.file.host_dir.path + "/usr/bin",
        "QNX_CONFIGURATION_EXCLUSIVE": ctx.file.qnx_license_path.path,
        "QNX_HOST": "/proc/self/cwd/" + ctx.file.host_dir.path,
        "QNX_SHARED_LICENSE_FILE": "{}/license/licenses".format(ctx.file.qnx_license_path.path),
        "QNX_TARGET": "/proc/self/cwd/" + ctx.file.target_dir.path,
    }

    return [
        platform_common.ToolchainInfo(
            tool_info = ToolInfo(
                env = env,
                executable = ctx.executable.executable,
                files = depset(ctx.files.host + ctx.files.target, transitive = [ctx.attr.executable.default_runfiles.files]),
            ),
        ),
    ]

qnx_fs_toolchain_config = rule(
    _impl,
    attrs = {
        "executable": attr.label(
            cfg = "exec",
            executable = True,
            mandatory = True,
        ),
        "host": attr.label(
            cfg = "exec",
            mandatory = True,
        ),
        "host_dir": attr.label(
            cfg = "exec",
            mandatory = True,
            allow_single_file = True,
        ),
        "qnx_license_path": attr.label(
            cfg = "exec",
            mandatory = True,
            allow_single_file = True,
        ),
        "target": attr.label(
            cfg = "exec",
            mandatory = True,
        ),
        "target_dir": attr.label(
            cfg = "exec",
            mandatory = True,
            allow_single_file = True,
        ),
    },
)
