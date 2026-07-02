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
load("@%{toolchain_repo_name}//qnx_toolchain/toolchains/fs:toolchain.bzl", "qnx_fs_toolchain_config")

qnx_fs_toolchain_config(
    name = "mkifs_toolchain",
    executable = "@%{toolchain_repo_name}//sdp:mkifs",
    host = "@%{toolchain_repo_name}//sdp:host_all",
    host_dir = "@%{toolchain_repo_name}//sdp:host_dir",
    qnx_license_path = "@%{toolchain_repo_name}//sdp:license",
    target = "@%{toolchain_repo_name}//sdp:target_all",
    target_dir = "@%{toolchain_repo_name}//sdp:target_dir",
)

toolchain(
    name = "ifs",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    target_compatible_with = [
        "@platforms//cpu:%{arch}",
        "@platforms//os:qnx",
    ],
    toolchain = ":mkifs_toolchain",
    toolchain_type = "@%{toolchain_repo_name}//qnx_toolchain/toolchains/fs/ifs:toolchain_type",
)
