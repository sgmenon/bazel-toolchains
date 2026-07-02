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

"""This module provides the cc_toolchain_config rule.
"""

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "action_config",
    "feature",
    "flag_group",
    "flag_set",
    "tool",
    "tool_path",
    "with_feature_set",
)
load("@rules_cc//cc:defs.bzl", "CcToolchainConfigInfo")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("//gcc_toolchain/fortran:action_names.bzl", FORTRAN_ACTION_NAMES = "ACTION_NAMES")

all_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.clif_match,
    ACTION_NAMES.lto_backend,
]

all_cpp_compile_actions = [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.clif_match,
]

preprocessor_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.clif_match,
]

codegen_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.lto_backend,
]

all_link_actions = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    FORTRAN_ACTION_NAMES.fortran_link_executable,
]

lto_index_actions = [
    ACTION_NAMES.lto_index_for_executable,
    ACTION_NAMES.lto_index_for_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]

def _impl(ctx):
    cxx_builtin_include_directories = ctx.attr.cxx_builtin_include_directories
    tool_paths = ctx.attr.tool_paths
    extra_cflags = ctx.attr.extra_cflags
    extra_cxxflags = ctx.attr.extra_cxxflags
    extra_fflags = ctx.attr.extra_fflags
    extra_ldflags = ctx.attr.extra_ldflags
    extra_asmflags = ctx.attr.extra_asmflags
    includes = ctx.attr.includes
    builtin_sysroot = ctx.attr.builtin_sysroot

    action_configs = []

    action_configs.append(action_config(
        action_name = "objcopy_embed_data",
        enabled = True,
        tools = [tool(path = tool_paths.get("objcopy"))],
    ))

    no_libstdcxx_feature = feature(name = "no_libstdcxx")
    static_libstdcxx_feature = feature(name = "static_libstdcxx")

    strong_warnings_feature = feature(
        name = "strong_warnings",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Wall",
                            "-Wformat",
                            "-Wformat-security",
                            "-Wno-error=deprecated-declarations",
                        ],
                    ),
                ],
                with_features = [
                    with_feature_set(not_features = ["third_party"]),
                ],
            ),
        ],
    )

    treat_warnings_as_errors_feature = feature(
        name = "treat_warnings_as_errors",
        flag_sets = [
            flag_set(
                actions = all_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Werror",
                        ],
                    ),
                ],
                with_features = [
                    with_feature_set(not_features = ["third_party"]),
                ],
            ),
        ],
    )

    strict_feature = feature(
        name = "strict",
        implies = ["strong_warnings", "treat_warnings_as_errors"],
        flag_sets = [
            flag_set(
                actions = all_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Wextra",
                        ],
                    ),
                ],
                with_features = [
                    with_feature_set(not_features = ["third_party"]),
                ],
            ),
        ],
    )

    pedantic_feature = feature(
        name = "pedantic",
        implies = ["strict"],
        flag_sets = [
            flag_set(
                actions = all_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Wpedantic",
                        ],
                    ),
                ],
                with_features = [
                    with_feature_set(not_features = ["third_party"]),
                ],
            ),
        ],
    )

    third_party_warnings_feature = feature(
        name = "third_party",
        flag_sets = [
            flag_set(
                actions = all_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [],
            ),
        ],
    )

    cxx14_feature = feature(
        name = "c++14",
        provides = ["cxx_std"],
        flag_sets = [
            flag_set(
                actions = all_cpp_compile_actions,
                flag_groups = [
                    flag_group(flags = ["-std=c++14"]),
                ],
            ),
        ],
    )

    cxx20_feature = feature(
        name = "c++20",
        provides = ["cxx_std"],
        flag_sets = [
            flag_set(
                actions = all_cpp_compile_actions,
                flag_groups = [
                    flag_group(flags = ["-std=c++20"]),
                ],
            ),
        ],
    )

    default_link_flags_feature = feature(
        name = "default_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Wl,-z,relro,-z,now",
                            "-pass-exit-codes",
                            "-lm",
                        ],
                    ),
                ],
            ),
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-lstdc++"],
                    ),
                ],
                with_features = [
                    with_feature_set(
                        not_features = [
                            "no_libstdcxx",
                            "static_libstdcxx",
                        ],
                    ),
                ],
            ),
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-l:libstdc++.a"],
                    ),
                ],
                with_features = [
                    with_feature_set(
                        not_features = ["no_libstdcxx"],
                        features = ["static_libstdcxx"],
                    ),
                ],
            ),
            flag_set(
                actions = all_link_actions,
                flag_groups = [flag_group(flags = ["-Wl,--gc-sections"])],
                with_features = [with_feature_set(features = ["opt"])],
            ),
        ],
    )

    unfiltered_compile_flags_feature = feature(
        name = "unfiltered_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [
                    flag_group(
                        flags = [
                            "-no-canonical-prefixes",
                            "-fno-canonical-system-headers",
                            "-Wno-builtin-macro-redefined",
                        ],
                    ),
                ],
            ),
        ],
    )

    redacted_dates_feature = feature(
        name = "redacted_dates",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-D__DATE__=\"redacted\"",
                            "-D__TIMESTAMP__=\"redacted\"",
                            "-D__TIME__=\"redacted\"",
                        ],
                    ),
                ],
            ),
        ],
    )

    supports_pic_feature = feature(
        name = "supports_pic",
        enabled = True,
    )

    fortran_compile_flags_feature = feature(
        name = "fortran_compile_flags",
        enabled = True,
    )

    static_libgfortran_feature = feature(name = "static_libgfortran")

    fortran_link_flags_feature = feature(
        name = "fortran_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [FORTRAN_ACTION_NAMES.fortran_link_executable],
                flag_groups = [
                    flag_group(
                        flags = ["-static-libgfortran"],
                    ),
                ],
                with_features = [
                    with_feature_set(
                        features = ["static_libgfortran"],
                    ),
                ],
            ),
        ],
    )

    action_configs.append(action_config(
        action_name = FORTRAN_ACTION_NAMES.fortran_compile,
        enabled = True,
        tools = [tool(path = tool_paths.get("gfortran"))],
    ))

    action_configs.append(action_config(
        action_name = FORTRAN_ACTION_NAMES.fortran_link_executable,
        enabled = True,
        tools = [tool(path = tool_paths.get("gfortran"))],
    ))

    action_configs.append(action_config(
        action_name = FORTRAN_ACTION_NAMES.fortran_archive,
        enabled = True,
        tools = [tool(path = tool_paths.get("ar"))],
    ))

    default_compile_flags_feature = feature(
        name = "default_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_cpp_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-fstack-protector-strong",
                            "-fdiagnostics-color=always",
                        ],
                    ),
                ],
            ),
            flag_set(
                actions = all_cpp_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-U_FORTIFY_SOURCE",
                            "-D_FORTIFY_SOURCE=1",
                        ],
                    ),
                ],
                with_features = [with_feature_set(features = ["opt"])],
            ),
            flag_set(
                actions = all_cpp_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [flag_group(flags = [
                    "-Og",
                    "-g",
                    "-fno-omit-frame-pointer",
                    "-fasynchronous-unwind-tables",
                ])],
                with_features = [with_feature_set(features = ["dbg"])],
            ),
            flag_set(
                actions = all_cpp_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-O3",
                            "-DNDEBUG",
                            "-ffunction-sections",
                            "-fdata-sections",
                        ],
                    ),
                ],
                with_features = [with_feature_set(features = ["opt"])],
            ),
            # default to c++17 unless otherwise specified
            flag_set(
                actions = all_cpp_compile_actions + [ACTION_NAMES.lto_backend],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-std=c++17",
                        ],
                    ),
                ],
                with_features = [
                    with_feature_set(not_features = ["c++14", "c++20"]),
                ],
            ),
        ],
    )

    sanitizer_extra_ldflags = []
    tsan_extra_cflags = []
    compiler_major_version = int(ctx.attr.compiler_version.replace("gcc", ""))
    if compiler_major_version < 10:
        sanitizer_extra_ldflags += [
            "-ldl",  # Required by libtsan.so for dlsym, dlvsym
            "-lrt",  # Required by libtsan.so for shm_open, shm_unlink
        ]
    elif compiler_major_version >= 12:
        tsan_extra_cflags.append("-Wno-error=tsan")

    sanitizers = [
        struct(
            name = "asan",
            cflags = [
                "-fsanitize=address",
                "-DADDRESS_SANITIZER",
                "-O1",
                "-g",
                "-fno-omit-frame-pointer",
                "-fasynchronous-unwind-tables",
            ],
            ldflags = ["-fsanitize=address"] + sanitizer_extra_ldflags,
        ),
        struct(
            name = "lsan",
            cflags = [
                "-fsanitize=leak",
                "-O1",
                "-g",
                "-fno-omit-frame-pointer",
                "-fasynchronous-unwind-tables",
            ],
            ldflags = [
                "-fsanitize=leak",
            ] + sanitizer_extra_ldflags,
        ),
        struct(
            name = "tsan",
            cflags = [
                "-fsanitize=thread",
                "-O1",
                "-g",
                "-fno-omit-frame-pointer",
                "-fasynchronous-unwind-tables",
            ] + tsan_extra_cflags,
            ldflags = [
                "-fsanitize=thread",
            ] + sanitizer_extra_ldflags,
        ),
        struct(
            name = "ubsan",
            cflags = [
                "-O1",
                "-fsanitize=undefined",
                "-g",
                "-fno-omit-frame-pointer",
                "-fasynchronous-unwind-tables",
            ],
            ldflags = [
                "-fsanitize=undefined",
            ] + sanitizer_extra_ldflags,
        ),
    ]

    sanitizers_features = [
        _sanitizer_feature(sanitizer)
        for sanitizer in sanitizers
    ]

    include_paths_feature = feature(
        name = "include_paths",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.clif_match,
                    ACTION_NAMES.objc_compile,
                    ACTION_NAMES.objcpp_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-iquote", "%{quote_include_paths}"],
                        iterate_over = "quote_include_paths",
                    ),
                    flag_group(
                        flags = ["-I%{include_paths}"],
                        iterate_over = "include_paths",
                    ),
                    flag_group(
                        flags = ["-isystem", "%{system_include_paths}"],
                        iterate_over = "system_include_paths",
                    ),
                ],
            ),
        ],
    )

    library_search_directories_feature = feature(
        name = "library_search_directories",
        flag_sets = [
            flag_set(
                actions = all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        flags = ["-L%{library_search_directories}"],
                        iterate_over = "library_search_directories",
                        expand_if_available = "library_search_directories",
                    ),
                ],
            ),
        ],
    )

    opt_feature = feature(name = "opt")

    supports_dynamic_linker_feature = feature(
        name = "supports_dynamic_linker",
        enabled = True,
    )

    supports_fission_feature = feature(
        name = "supports_fission",
        enabled = True,
        # Bazel automatically adds --gdb-index when fission is enabled
    )

    objcopy_embed_flags_feature = feature(
        name = "objcopy_embed_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = ["objcopy_embed_data"],
                flag_groups = [flag_group(flags = ["-I", "binary"])],
            ),
        ],
    )

    dbg_feature = feature(name = "dbg")

    per_object_debug_info_feature = feature(
        name = "per_object_debug_info",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    FORTRAN_ACTION_NAMES.fortran_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-g", "-gsplit-dwarf"],
                        expand_if_available = "is_using_fission",
                    ),
                ],
            ),
        ],
    )

    force_debug = feature(
        name = "force_debug",
        flag_sets = [
            flag_set(
                actions = all_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [
                    flag_group(
                        flags = ["-g"],
                        expand_if_not_available = "is_using_fission",
                    ),
                ],
                with_features = [
                    with_feature_set(
                        features = ["opt"],
                    ),
                    with_feature_set(
                        features = ["fastbuild"],
                    ),
                ],
            ),
        ],
    )

    user_compile_flags_feature = feature(
        name = "user_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [
                    flag_group(
                        flags = ["%{user_compile_flags}"],
                        iterate_over = "user_compile_flags",
                        expand_if_available = "user_compile_flags",
                    ),
                ],
            ),
        ],
    )

    extra_cflags_feature = feature(
        name = "extra_cflags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [ACTION_NAMES.c_compile],
                flag_groups = [flag_group(flags = extra_cflags)],
            ),
        ] if len(extra_cflags) > 0 else [],
    )

    extra_cxxflags_feature = feature(
        name = "extra_cxxflags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [ACTION_NAMES.cpp_compile],
                flag_groups = [flag_group(flags = extra_cxxflags)],
            ),
        ] if len(extra_cxxflags) > 0 else [],
    )

    extra_fflags_feature = feature(
        name = "extra_fflags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [flag_group(flags = extra_fflags)],
            ),
        ] if len(extra_fflags) > 0 else [],
    )

    includes_feature = feature(
        name = "includes",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [flag_group(flags = [
                    "-isystem{}".format(include)
                    for include in includes
                ])],
            ),
        ] if len(includes) > 0 else [],
    )

    extra_ldflags_feature = feature(
        name = "extra_ldflags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [flag_group(flags = extra_ldflags)],
            ),
        ] if len(extra_ldflags) > 0 else [],
    )

    extra_asmflags_feature = feature(
        name = "extra_asmflags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [ACTION_NAMES.preprocess_assemble],
                flag_groups = [flag_group(flags = extra_asmflags)],
            ),
        ] if len(extra_asmflags) > 0 else [],
    )

    sysroot_feature = feature(
        name = "sysroot",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.lto_backend,
                    ACTION_NAMES.clif_match,
                    FORTRAN_ACTION_NAMES.fortran_compile,
                ] + all_link_actions + lto_index_actions,
                flag_groups = [
                    flag_group(
                        flags = ["--sysroot", "%{sysroot}"],
                    ),
                ],
            ),
        ],
    )

    features = sanitizers_features + [
        fortran_compile_flags_feature,
        static_libgfortran_feature,
        fortran_link_flags_feature,
        default_compile_flags_feature,
        include_paths_feature,
        library_search_directories_feature,
        no_libstdcxx_feature,
        static_libstdcxx_feature,
        strong_warnings_feature,
        strict_feature,
        pedantic_feature,
        treat_warnings_as_errors_feature,
        third_party_warnings_feature,
        cxx14_feature,
        cxx20_feature,
        default_link_flags_feature,
        supports_dynamic_linker_feature,
        supports_pic_feature,
        supports_fission_feature,
        objcopy_embed_flags_feature,
        opt_feature,
        dbg_feature,
        per_object_debug_info_feature,
        force_debug,
        user_compile_flags_feature,
        sysroot_feature,
        unfiltered_compile_flags_feature,
        redacted_dates_feature,
        extra_cflags_feature,
        extra_cxxflags_feature,
        extra_fflags_feature,
        extra_ldflags_feature,
        extra_asmflags_feature,
        includes_feature,
    ]

    # Make toolchain identifier version-specific
    compiler_version = ctx.attr.compiler_version
    toolchain_id = "local_linux_{}".format(compiler_version)
    return [
        cc_common.create_cc_toolchain_config_info(
            abi_libc_version = "local",
            abi_version = "local",
            action_configs = action_configs,
            artifact_name_patterns = [],
            builtin_sysroot = builtin_sysroot,
            cc_target_os = None,
            compiler = "gcc",
            ctx = ctx,
            cxx_builtin_include_directories = cxx_builtin_include_directories,
            features = features,
            host_system_name = "local",
            make_variables = [],
            target_cpu = "local",
            target_libc = "local",
            target_system_name = "local",
            tool_paths = [
                tool_path(name = name, path = path)
                for name, path in tool_paths.items()
            ],
            toolchain_identifier = toolchain_id,
        ),
    ]

cc_toolchain_config = rule(
    implementation = _impl,
    attrs = {
        "builtin_sysroot": attr.string(mandatory = True),
        "compiler_version": attr.string(mandatory = True),
        "cxx_builtin_include_directories": attr.string_list(mandatory = True),
        "extra_asmflags": attr.string_list(default = []),
        "extra_cflags": attr.string_list(mandatory = True),
        "extra_cxxflags": attr.string_list(mandatory = True),
        "extra_fflags": attr.string_list(mandatory = True),
        "extra_ldflags": attr.string_list(mandatory = True),
        "includes": attr.string_list(default = []),
        "tool_paths": attr.string_dict(mandatory = True),
    },
    provides = [CcToolchainConfigInfo],
)

def _sanitizer_feature(sanitizer):
    feature_sets = [with_feature_set(
        features = [sanitizer.name],
        not_features = ["opt"],
    )]
    return feature(
        name = sanitizer.name,
        flag_sets = [
            flag_set(
                actions = all_compile_actions + [FORTRAN_ACTION_NAMES.fortran_compile],
                flag_groups = [
                    flag_group(
                        flags = sanitizer.cflags,
                    ),
                ],
                with_features = feature_sets,
            ),
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = sanitizer.ldflags,
                    ),
                ],
                with_features = feature_sets,
            ),
        ],
    )
