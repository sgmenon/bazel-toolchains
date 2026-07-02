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

"""Helper function to register toolchains in MODULE.bazel"""

load("//gcc_toolchain:gcc_defs.bzl", "ARCHS", "GCC_VERSIONS", "gcc_register_toolchain")

def _get_desired_variants(module_ctx):
    """Extract desired arch from tag classes."""
    versions = []
    for mod in module_ctx.modules:
        for attr in mod.tags.load_toolchain:
            versions.append({
                "arch": attr.arch,
                "toolchain_workspace_name": attr.toolchain_workspace_name,
                "gcc_version": attr.gcc_version,
                "path_to_toolchain": attr.path_to_toolchain,
            })
    return versions

def _gcc_toolchain_impl(module_ctx):
    variants = _get_desired_variants(module_ctx)
    for variant_info in variants:
        arch = variant_info["arch"]
        target_arch = arch
        compiler_version = variant_info["gcc_version"]
        toolchain_workspace_name = variant_info["toolchain_workspace_name"]
        path_to_toolchain = variant_info["path_to_toolchain"]
        arch = getattr(ARCHS, arch, "")
        gcc_version = GCC_VERSIONS[compiler_version]
        if not arch:
            fail("Invalid arch: {}".format(arch))
        gcc_register_toolchain(
            name = "gcc_toolchain_{}-{}".format(arch, compiler_version),
            target_arch = target_arch,
            gcc_version = gcc_version,
            toolchain_workspace_name = toolchain_workspace_name,
            path_to_toolchain = path_to_toolchain,
        )

_attrs = tag_class(attrs = {
    "arch": attr.string(mandatory = True),
    "toolchain_workspace_name": attr.string(default = "bazel-toolchains"),
    "gcc_version": attr.string(mandatory = True),
    "path_to_toolchain": attr.string(default = "gcc_toolchain"),
})

gcc_toolchain_extension = module_extension(
    implementation = _gcc_toolchain_impl,
    tag_classes = {
        "load_toolchain": _attrs,
    },
)
