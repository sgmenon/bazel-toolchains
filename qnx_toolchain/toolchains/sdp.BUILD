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
package(default_visibility = [
    "//visibility:public",
])

filegroup(
    name = "all_files",
    srcs = glob(["*/**/*"]),
)

filegroup(
    name = "cxx_builtin_include_directories",
    srcs = [
        "host/linux/x86_64/usr/lib/gcc/%{arch}-%{abi}-nto-qnx%{qnx_version}/%{qcc_version}/include",
        "target/qnx7/usr/include",
        "target/qnx7/usr/include/c++/v1",
    ],
)

filegroup(
    name = "ar",
    srcs = ["host/linux/x86_64/usr/bin/%{arch}-%{abi}-nto-qnx%{qnx_version}-ar"],
)

filegroup(
    name = "qcc",
    srcs = ["host/linux/x86_64/usr/bin/qcc"],
)

filegroup(
    name = "objcopy",
    srcs = ["host/linux/x86_64/usr/bin/{arch}-%{abi}-nto-qnx%{qnx_version}-objcopy"],
)

filegroup(
    name = "nm",
    srcs = ["host/linux/x86_64/usr/bin/{arch}-%{abi}-nto-qnx%{qnx_version}-nm"],
)

filegroup(
    name = "objdump",
    srcs = ["host/linux/x86_64/usr/bin/{arch}-%{abi}-nto-qnx%{qnx_version}-objdump"],
)

filegroup(
    name = "qpp",
    srcs = ["host/linux/x86_64/usr/bin/q++"],
)

# this is a wrapped version that can handle -Xlinker flags
# Bazel's cc_import for cc_binary generates these and there's no way to change the flags to something elese
# however QCC doesn't understand -Xlinker so we transform it so that we use -Wl, instead
filegroup(
    name = "qpp_wrapper",
    srcs = ["host/linux/x86_64/usr/bin/qpp_wrapper.sh"],
)

filegroup(
    name = "strip",
    srcs = ["host/linux/x86_64/usr/bin/%{arch}-%{abi}-nto-qnx%{qnx_version}-strip"],
)

filegroup(
    name = "host_all",
    srcs = glob(["host/linux/x86_64/**/*"]),
)

filegroup(
    name = "host_dir",
    srcs = ["host/linux/x86_64"],
)

filegroup(
    name = "license",
    srcs = ["host/linux/x86_64/.qnx"],
)

filegroup(
    name = "target_all",
    srcs = glob(["target/qnx7/**/*"]),
)

filegroup(
    name = "target_dir",
    srcs = ["target/qnx7"],
)

filegroup(
    name = "mkifs",
    srcs = ["host/linux/x86_64/usr/bin/mkifs"],
)
