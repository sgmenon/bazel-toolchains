"""
This rule generates an Image File System (IFS) for QNX.

In order todo that, the user has to provide a main build file and supporting
files. The main build file will be used as entrypoint and can then include
other build files or perform other operations like packaging any file into the
created IFS.
"""

QNX_FS_TOOLCHAIN = "//qnx_toolchain/toolchains/fs/ifs:toolchain_type"

def _qnx_ifs_impl(ctx):
    """ Implementation function of qnx_ifs rule.

        This function will merge all .build files into main .build file and
        produce flashable QNX image.
    """
    inputs = []
    out_ifs = ctx.actions.declare_file("{}.{}".format(ctx.attr.name, ctx.attr.extension))

    ifs_tool_info = ctx.toolchains[QNX_FS_TOOLCHAIN].tool_info

    main_build_file = ctx.file.build_file

    inputs.append(main_build_file)
    inputs.extend(ctx.files.srcs)

    args = ctx.actions.args()
    args.add_all([
        main_build_file.path,
        out_ifs.path,
    ])

    ctx.actions.run(
        outputs = [out_ifs],
        inputs = inputs,
        arguments = [args],
        executable = ifs_tool_info.executable,
        env = ifs_tool_info.env,
        tools = ifs_tool_info.files,
    )

    return [
        DefaultInfo(files = depset([out_ifs])),
    ]

qnx_ifs = rule(
    implementation = _qnx_ifs_impl,
    toolchains = [QNX_FS_TOOLCHAIN],
    attrs = {
        "build_file": attr.label(
            allow_single_file = True,
            doc = "Single label that points to the main build file (entrypoint)",
            mandatory = True,
        ),
        "extension": attr.string(
            default = "ifs",
            doc = "Extension for the generated IFS image. Manipulating this extensions is a workaround for IPNext startup code limitation, when interpreting ifs images. This attribute will either disappear or will be replaced by toolchain configuration in order to keep output files consistent.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "List of labels that are used by the `build_file`",
            allow_empty = True,
        ),
    },
)
