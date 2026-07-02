# bazel-toolchains

## Overview

`bazel-toolchains` provides a Bazel C++ toolchain and wrapper rules for building C++ code with a prebuilt `GCC` toolchain. It is designed for `Linux` environments with any Bazel repo.

The idea behind this toolchain is that it uses a `sysroot` that is either exported from `Yocto` (as an `SDK`) or which looks like a `Yocto` exported SDK. The scripts in the [sysroot](sysroot/README.md) folder generate such a `sysroot`.

This rootfs may contain a number of artifacts, however for the purposes of cross compiling we just need an `sysroot` for building binaries that run on that rootfs. We expect this sysroot to contain a few things that must line up with the artifacts from the production `rootfs`, for instance:

- GCC
- libstdc++
- libc (glibc)
- Linux Kernel Headers (from the exact linux version we are targeting)
- Core Linux System libraries. For example:
  - libpthread (POSIX threads)
  - librt (real-time extensions)
  - libdl (dynamic linking)
  - libutil (misc system utilities)
- Other common Linux libraries
  - libacl – Access Control Lists
  - libattr – Extended file attributes
  - libmount – Mounting filesystems
  - libblkid – Block device identification
  - libx11/libwayland – working with displays (for front-end apps that use libqt for example)

## Key Features

- Multi-architecture: Support for x86_64, aarch64, and armv7 Linux targets.
- Hermetic: Fully self-contained with no system dependencies.
- Optimized: Reduced toolchain sizes and improved build performance.
- Fortran Support: Complete Fortran compilation, including OpenMP support.
- Sanitizers: Built-in support for AddressSanitizer, LeakSanitizer, ThreadSanitizer, and UndefinedBehaviorSanitizer.
- Remote Execution: Ready for use with Bazel Remote Build Execution (RBE).

## Usage

### 1. Add bazel-toolchains as a dependency

In your consuming repo's `MODULE.bazel`:

```starlark
bazel_dep(name = "bazel-toolchains", version = "<version>")
bazel_dep(name = "platforms", version = "1.0.0")  # Required for platform/constraint support
bazel_dep(name = "bazel_skylib", version = "1.8.1")
bazel_dep(name = "aspect_bazel_lib", version = "1.40.2")
```

### 2. Register the toolchain

In your consuming repo's `MODULE.bazel` or `WORKSPACE`:

Assuming you want to have a GCC toolchain for

```starlark
gcc_toolchain_extension = use_extension("@bazel-toolchains//gcc_toolchain:toolchain_extension.bzl", "gcc_toolchain_extension", dev_dependency = True)
[
    [
        [
            gcc_toolchain_extension.load_toolchain(
                arch = arch,
                gcc_version = gcc_version,
            ),
            use_repo(
                gcc_toolchain_extension,
                "gcc_toolchain_{arch}-{gcc_version}".format(
                    arch = arch,
                    gcc_version = gcc_version,
                ),
            ),
        ]
        for arch in [
            "x86_64",
            "aarch64",
        ]
    ]
    for gcc_version in [
        "gcc11",
        "gcc13",
    ]
]
# [OPTIONAL] register default toolchians here
register_toolchains("@gcc_toolchain_x86_64-gcc11//:cc_toolchain")
register_toolchains("@gcc_toolchain_x86_64-gcc11//:fortran_toolchain")

# For QNX Toolchains
qnx_toolchain_extension = use_extension("//qnx_toolchain:extensions.bzl", "toolchains_qnx", dev_dependency = True)
qnx_toolchain_extension.sdp(
    name = "qnx",
    arch = [
        "aarch64",
        "x86_64",
    ],
    qnx_license_path = "//:.qnx",
    sha256 = "<sha256>",
    strip_prefix = "qos220",
    url = "https://path/to/qnx/sdp.tar.gz",
)
use_repo(qnx_toolchain_extension, "qnx_aarch64_sdp")
use_repo(qnx_toolchain_extension, "qnx_aarch64_qcc")
use_repo(qnx_toolchain_extension, "qnx_x86_64_sdp")
use_repo(qnx_toolchain_extension, "qnx_x86_64_qcc")
```

## Recommended: Bazel Config for Convenience

For easier adoption, you can add a Bazel config (e.g., `--config=gcc11`) to your `.bazelrc`:

For example, if your host system is `Ubuntu 22`, it may make sense to use `x86_64_linux_gcc11` as your host platform configuration.

Similarly, if your host system is `Ubuntu 24`, it makes sense to use `x86_64_linux_gcc13` as your host platform configuration.

```sh
# .bazelrc
build:common  --host_platform=//platforms:x86_64_linux_gcc11
build:common --platforms=//platforms:x86_64_linux_gcc11
# no need for extra toolchains if its already registered in bazelrc

build:gcc13 --platforms=//platforms:x86_64_linux_gcc13
build:gcc13 --extra_toolchains=@gcc_toolchain_x86_64-gcc13//:cc_toolchain
build:gcc13 --extra_toolchains=@gcc_toolchain_x86_64-gcc13//:fortran_toolchain

# fission support is a new GCC feature and needs the GOLD linker
build:aarch64_qnx --fission=no
build:aarch64_qnx --platforms=//platforms:aarch64_qnx
build:aarch64_qnx --platform_suffix=aarch64_qnx
build:aarch64_qnx --extra_toolchains=@qnx_aarch64_qcc//:qcc
```

Then build with:

```sh
bazel build --config=gcc13 //your:target
```
