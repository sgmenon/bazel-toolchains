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

"""This module provides the definitions for registering a GCC toolchain for C and C++.
"""

load("@aspect_bazel_lib//lib:utils.bzl", "is_bzlmod_enabled")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")

ARCHS = struct(
    aarch64 = "aarch64",
    x86_64 = "x86_64",
)

_DEFAULT_GCC_VERSION = "13.4.0"

GCC_VERSIONS = {
    "gcc11": "11.3.0",
    "gcc13": _DEFAULT_GCC_VERSION,
    "gcc8": "8.4.0",
}

def _gcc_toolchain_impl(rctx):
    versions = json.decode(rctx.attr.gcc_versions)
    rctx.download_and_extract(
        url = versions[rctx.attr.gcc_version][rctx.attr.target_arch]["url"],
        sha256 = versions[rctx.attr.gcc_version][rctx.attr.target_arch]["sha256"],
    )

    absolute_toolchain_root = str(rctx.path("."))
    execroot = paths.normalize(paths.join(absolute_toolchain_root, "..", ".."))
    toolchain_root = paths.relativize(absolute_toolchain_root, execroot)

    def _format_flags(flags):
        return str([
            flag.replace("%workspace%", toolchain_root)
            for flag in flags
        ])

    def _format_builtins(builtins):
        # In bzlmod, external dependencies have their own canonical subdirectories, so we can't rely on %workspace%.
        # Instead, we want to resolve paths relative to the root of the module where the toolchain is installed.
        if is_bzlmod_enabled():
            return str([d.replace("%workspace%", toolchain_root) for d in builtins])
        return str(builtins)

    target_arch = rctx.attr.target_arch

    binary_prefix = rctx.attr.binary_prefix
    tool_paths = _render_tool_paths(rctx, toolchain_root, binary_prefix)
    rctx.file("tool_paths.bzl", "tool_paths = {}".format(str(tool_paths)))

    include_prefix = None
    if target_arch == ARCHS.aarch64:
        include_prefix = "aarch64-linux/"
    elif target_arch == ARCHS.x86_64:
        include_prefix = "x86_64-linux/"

    c_builtin_includes = [
        include.format(
            gcc_version = rctx.attr.gcc_version,
            include_prefix = include_prefix,
        )
        for include in [
            "%workspace%/lib/gcc/{include_prefix}{gcc_version}/include",
            "%workspace%/lib/gcc/{include_prefix}{gcc_version}/include-fixed",
        ] + ([
            "%workspace%/{include_prefix}include",
        ] if target_arch != ARCHS.x86_64 else []) + [
            "%workspace%/sysroot/usr/include",
        ]
    ]

    cxx_builtin_includes = []
    if target_arch == ARCHS.x86_64:
        cxx_builtin_includes.extend([
            include.format(
                gcc_version = rctx.attr.gcc_version,
                include_prefix = include_prefix,
            )
            for include in [
                "%workspace%/include/c++/{gcc_version}",
                "%workspace%/include/c++/{gcc_version}/{include_prefix}",
                "%workspace%/include/c++/{gcc_version}/backward",
            ]
        ])
    else:
        cxx_builtin_includes.extend([
            include.format(
                gcc_version = rctx.attr.gcc_version,
                include_prefix = include_prefix,
            )
            for include in [
                "%workspace%/{include_prefix}include/c++/{gcc_version}",
                "%workspace%/{include_prefix}include/c++/{gcc_version}/{include_prefix}",
                "%workspace%/{include_prefix}include/c++/{gcc_version}/backward",
            ]
        ])

    f_builtin_includes = [
        include.format(
            gcc_version = rctx.attr.gcc_version,
            include_prefix = include_prefix,
        )
        for include in [
            "%workspace%/lib/gcc/{include_prefix}{gcc_version}/finclude",
        ]
    ]

    compiler_version = "gcc{}".format(rctx.attr.gcc_version.split(".")[0])

    target_compatible_with = [
        v.format(
            target_arch = target_arch,
            compiler_version = compiler_version,
            toolchain_workspace_name = rctx.attr.toolchain_workspace_name,
        )
        for v in rctx.attr.target_compatible_with
    ]

    target_settings = [
        v.format(target_arch = target_arch)
        for v in rctx.attr.target_settings
    ]

    builtin_include_directories = []
    builtin_include_directories.extend(c_builtin_includes)
    builtin_include_directories.extend(cxx_builtin_includes)
    builtin_include_directories.extend(f_builtin_includes)
    builtin_include_directories.extend(rctx.attr.includes)
    builtin_include_directories.extend(rctx.attr.fincludes)

    extra_cflags = [
        "-nostdinc",
        "-B%workspace%/bin",
        "-B%workspace%/xbin",
    ]
    extra_cflags.extend([
        "-isystem{}".format(include)
        for include in c_builtin_includes
    ])
    extra_cflags.extend([
        "-I{}".format(include)
        for include in rctx.attr.includes
    ])
    extra_cflags.extend(rctx.attr.extra_cflags)

    extra_cxxflags = [
        "-nostdinc",
        "-nostdinc++",
        "-B%workspace%/bin",
        "-B%workspace%/xbin",
    ]
    extra_cxxflags.extend([
        "-isystem{}".format(include)
        for include in cxx_builtin_includes
    ])
    extra_cxxflags.extend([
        "-isystem{}".format(include)
        for include in c_builtin_includes
    ])
    extra_cxxflags.extend([
        "-I{}".format(include)
        for include in rctx.attr.includes
    ])
    extra_cxxflags.extend(rctx.attr.extra_cxxflags)

    extra_fflags = [
        "-nostdinc",
        "-B%workspace%/bin",
        "-B%workspace%/xbin",
    ]
    extra_fflags.extend([
        "-I{}".format(include)
        for include in f_builtin_includes
    ])
    extra_fflags.extend([
        "-I{}".format(include)
        for include in c_builtin_includes
    ])
    extra_fflags.extend([
        "-I{}".format(finclude)
        for finclude in rctx.attr.fincludes
    ])
    extra_fflags.extend(rctx.attr.extra_fflags)

    extra_ldflags = [
        lib.format(
            include_prefix = include_prefix,
        )
        for lib in [
            "-B%workspace%/bin",
            "-B%workspace%/xbin",
            "-B%workspace%/lib",
            "-B%workspace%/{include_prefix}lib",
            "-B%workspace%/lib64",
            "-B%workspace%/{include_prefix}lib64",
            "-B%workspace%/sysroot/lib",
            "-B%workspace%/sysroot/usr/lib",
            "-L%workspace%/lib",
            "-L%workspace%/{include_prefix}lib",
            "-L%workspace%/lib64",
            "-L%workspace%/{include_prefix}lib64",
            "-L%workspace%/sysroot/lib",
            "-L%workspace%/sysroot/usr/lib",
        ]
    ]
    extra_ldflags.extend(rctx.attr.extra_ldflags)

    extra_asmflags = []
    extra_asmflags.extend([
        "-isystem{}".format(include)
        for include in c_builtin_includes
    ])
    extra_asmflags.extend([
        "-I{}".format(include)
        for include in rctx.attr.includes
    ])
    extra_asmflags.extend(rctx.attr.extra_asmflags)
    rctx.template(
        "BUILD.bazel",
        Label("@{}//{}:templates/toolchain.BUILD.tpl".format(rctx.attr.toolchain_workspace_name, rctx.attr.path_to_toolchain)),
        substitutions = {
            "%binary_prefix%": binary_prefix,
            # Compiler version
            "%compiler_version%": compiler_version,
            # Includes
            "%cxx_builtin_include_directories%": _format_builtins(builtin_include_directories),
            "%extra_asmflags%": _format_flags(extra_asmflags),
            # Flags
            "%extra_cflags%": _format_flags(extra_cflags),
            "%extra_cxxflags%": _format_flags(extra_cxxflags),
            "%extra_fflags%": _format_flags(extra_fflags),
            "%extra_ldflags%": _format_flags(extra_ldflags),
            "%toolchain_workspace_name%": rctx.attr.toolchain_workspace_name,
            "%include_prefix%": include_prefix,
            "%path_to_toolchain%": rctx.attr.path_to_toolchain,
            "%path_to_toolchain_files%": rctx.attr.path_to_toolchain,
            "%sysroot%": "{}/sysroot".format(toolchain_root),
            "%target_compatible_with%": str(target_compatible_with),
            "%target_settings%": str(target_settings),
        },
    )

AVAILABLE_GCC_VERSIONS = {
    "11.3.0": {
        "aarch64": {
            "sha256": "7e130eec00803790fad1f082c460c761b07508cccaa0c7859ae672ef3cbbab6e",
            "url": "https://github.com/sgmenon/bazel-toolchains/releases/download/v1.0.0/toolchain-base-gcc11.3.0-aarch64.tar.xz",
        },
        "x86_64": {
            "sha256": "132f8bd08e07d9ff88b1399973389375d5219b5daa5e7418d23283634d746374",
            "url": "https://github.com/sgmenon/bazel-toolchains/releases/download/v1.0.0/toolchain-base-gcc11.3.0-x86_64.tar.xz",
        },
    },
    "13.4.0": {
        "aarch64": {
            "sha256": "e8021828ea59766c0c57c0d2a5220a027c2aeecb97368a2ee3389b70b2e1d22f",
            "url": "https://github.com/sgmenon/bazel-toolchains/releases/download/v1.0.0/toolchain-base-gcc13.4.0-aarch64.tar.xz",
        },
        "x86_64": {
            "sha256": "f019cbb81c082178161a4a4fa818c7c92b43b5732797c6218b4916f604ae21ff",
            "url": "https://github.com/sgmenon/bazel-toolchains/releases/download/v1.0.0/toolchain-base-gcc13.4.0-x86_64.tar.xz",
        },
    },
}

_FEATURE_ATTRS = {
    "binary_prefix": attr.string(
        doc = "An explicit prefix used by each binary in bin/.",
        mandatory = True,
    ),
    "extra_asmflags": attr.string_list(
        doc = "Extra flags for the assembly preprocessor.",
        default = [],
    ),
    "extra_cflags": attr.string_list(
        doc = "Extra flags for compiling C.",
        default = [],
    ),
    "extra_cxxflags": attr.string_list(
        doc = "Extra flags for compiling C++.",
        default = [],
    ),
    "extra_fflags": attr.string_list(
        doc = "Extra flags for compiling Fortran.",
        default = [],
    ),
    "extra_ldflags": attr.string_list(
        doc = "Extra flags for linking." +
              " %workspace% is rendered to the toolchain root path." +
              " See https://github.com/bazelbuild/bazel/blob/a48e246e/src/main/java/com/google/devtools/build/lib/rules/cpp/CcToolchainProviderHelper.java#L234-L254.",
        default = [],
    ),
    "fincludes": attr.string_list(
        doc = "Extra includes for compiling Fortran." +
              " %workspace% is rendered to the toolchain root path.",
        default = [],
    ),
    "toolchain_workspace_name": attr.string(
        doc = "The name given to the gcc-toolchain repository, if the default was not used.",
        default = "gcc_toolchain",
    ),
    "gcc_version": attr.string(
        default = _DEFAULT_GCC_VERSION,
        doc = "The version of GCC.",
    ),
    "gcc_versions": attr.string(
        default = json.encode(AVAILABLE_GCC_VERSIONS),
        doc = "A JSON dictionary of GCC versions to their download URLs and SHA256 hashes." +
              " The structure is {<gcc_version>: {<target_arch>: {url: <url>, sha256: <sha256>}}}.",
    ),
    "includes": attr.string_list(
        doc = "Extra includes for compiling C and C++." +
              " %workspace% is rendered to the toolchain root path." +
              " See https://github.com/bazelbuild/bazel/blob/a48e246e/src/main/java/com/google/devtools/build/lib/rules/cpp/CcToolchainProviderHelper.java#L234-L254.",
        default = [],
    ),
    "path_to_toolchain": attr.string(
        doc = "The path to the toolchain files.",
        default = "toolchain",
    ),
    "target_arch": attr.string(
        doc = "The target architecture this toolchain produces. E.g. x86_64.",
        mandatory = True,
    ),
    "target_compatible_with": attr.string_list(
        default = [
            "@platforms//os:linux",
            "@platforms//cpu:{target_arch}",
            "@{toolchain_workspace_name}//platforms:{compiler_version}",
        ],
        doc = "contraint_values passed to target_compatible_with of the toolchain. {target_arch} is rendered to the target_arch attribute value, and {compiler_version} is rendered to the major version of the gcc_version attribute value.",
        mandatory = False,
    ),
    "target_settings": attr.string_list(
        default = [],
        doc = "config_settings passed to target_compatible_with of the toolchain. {target_arch} is rendered to the target_arch attribute value.",
        mandatory = False,
    ),
}

gcc_toolchain = repository_rule(
    _gcc_toolchain_impl,
    attrs = dicts.add(
        _FEATURE_ATTRS,
    ),
)

ATTRS_SHARED_WITH_MODULE_EXTENSION = {
    attr_name: _FEATURE_ATTRS[attr_name]
    for attr_name in ["gcc_version", "gcc_versions", "extra_cflags", "extra_cxxflags", "extra_ldflags", "extra_fflags", "extra_asmflags"]
}

def _render_tool_paths(rctx, path_prefix, binary_prefix):
    relative_tool_paths = {
        "ar": "{path_prefix}/bin/{binary_prefix}ar".format(
            path_prefix = path_prefix,
            binary_prefix = binary_prefix,
        ),
        "as": "{path_prefix}/bin/{binary_prefix}as".format(
            path_prefix = path_prefix,
            binary_prefix = binary_prefix,
        ),
        "cpp": "{path_prefix}/bin/{binary_prefix}cpp".format(
            path_prefix = path_prefix,
            binary_prefix = binary_prefix,
        ),
        "g++": "{path_prefix}/bin/{binary_prefix}g++".format(
            path_prefix = path_prefix,
            binary_prefix = binary_prefix,
        ),
        "gcc": "{path_prefix}/bin/{binary_prefix}gcc".format(
            path_prefix = path_prefix,
            binary_prefix = binary_prefix,
        ),
        "gcov": "{path_prefix}/bin/{binary_prefix}gcov".format(
            path_prefix = path_prefix,
            binary_prefix = binary_prefix,
        ),
        "gfortran": "{path_prefix}/bin/{binary_prefix}gfortran".format(
            path_prefix = path_prefix,
            binary_prefix = binary_prefix,
        ),
        "ld": "{path_prefix}/bin/{binary_prefix}ld".format(
            path_prefix = path_prefix,
            binary_prefix = binary_prefix,
        ),
        "nm": "{path_prefix}/bin/{binary_prefix}nm".format(
            path_prefix = path_prefix,
            binary_prefix = binary_prefix,
        ),
        "objcopy": "{path_prefix}/bin/{binary_prefix}objcopy".format(
            path_prefix = path_prefix,
            binary_prefix = binary_prefix,
        ),
        "objdump": "{path_prefix}/bin/{binary_prefix}objdump".format(
            path_prefix = path_prefix,
            binary_prefix = binary_prefix,
        ),
        "strip": "{path_prefix}/bin/{binary_prefix}strip".format(
            path_prefix = path_prefix,
            binary_prefix = binary_prefix,
        ),
    }

    path_env = ":".join([
        path.format(
            path_prefix = path_prefix,
        )
        for path in [
            # xbin first so that wrappers are found first in PATH when called
            # indirectly by other tools.
            "${{EXECROOT}}/{path_prefix}/xbin",
            "${{EXECROOT}}/{path_prefix}/bin",
        ]
    ])

    tool_paths = {}
    for name, tool_path in relative_tool_paths.items():
        wrapped_tool_path = paths.join("xbin", name)
        rctx.template(
            wrapped_tool_path,
            Label(
                "@{toolchain_workspace_name}//{path_to_toolchain}:wrapper.sh.tpl".format(
                    toolchain_workspace_name = rctx.attr.toolchain_workspace_name,
                    path_to_toolchain = rctx.attr.path_to_toolchain,
                ),
            ),
            substitutions = {
                "__PATH__": path_env,
                "__binary__": tool_path,
            },
            executable = True,
        )
        tool_paths[name] = wrapped_tool_path
    return tool_paths

def gcc_register_toolchain(
        name,
        target_arch,
        **kwargs):
    """Declares a `gcc_toolchain`.

    You should use `gcc_register_toolchain` unless you need to register toolchains manually,
    e.g. if you are consuming this repository as a Bzlmod dependency.

    Args:
        name: The name passed to `gcc_toolchain`.
        target_arch: The target architecture of the toolchain.
        **kwargs: The extra arguments passed to `gcc_toolchain`. See `gcc_toolchain` for more info.
    """
    binary_prefix = kwargs.pop("binary_prefix", None)
    if binary_prefix == None:
        if target_arch == ARCHS.aarch64:
            binary_prefix = "aarch64-linux-"
        elif target_arch == ARCHS.x86_64:
            binary_prefix = ""
        else:
            fail("Unsupported target architecture: {}".format(target_arch))

    gcc_toolchain(
        name = name,
        binary_prefix = binary_prefix,
        extra_cflags = kwargs.pop("extra_cflags", []),
        extra_cxxflags = kwargs.pop("extra_cxxflags", []),
        extra_fflags = kwargs.pop("extra_fflags", []),
        extra_ldflags = kwargs.pop("extra_ldflags", []),
        extra_asmflags = kwargs.pop("extra_asmflags", []),
        includes = kwargs.pop("includes", []),
        fincludes = kwargs.pop("fincludes", []),
        target_arch = target_arch,
        **kwargs
    )
