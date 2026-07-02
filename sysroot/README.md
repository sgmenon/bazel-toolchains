# Sysroot

As GCC (and other toolchains) see it, the sysroot is the logical root directory for headers and
libraries.

This subdirectory contains the definitions and scripts to build sysroots for x86_64 and
aarch64 (aka armv8).

All we have in a sysroot is the bare-minimum to do cross compilation with a bazel toolchain:

- GCC (libstdc++ and libc compiled with debug symbols so the bundle is larger but this is better for local debugging workflows)
- GLIBC
- ACL
- (optionally) common libraries like X11 needed for working with displays

This isn't a full working systemd capable sysroot, in other words it is primarily meant as an SDK for development, but is far more lightweight than what is generated from a YOCTO `populate_sdk` command.

## Building the sysroots

Use the `build.sh` script to build the sysroots using Docker. The current restriction is
that the container must run in `x86_64`. The sysroots for other architectures are built using
cross-compilation from `x86_64`.

It will not be too hard to extend this build script to work with other host-platforms, but right now the use cases does not exist.

### Using the build script

```shell
./sysroot/build.sh x86_64 ./sysroot base
./sysroot/build.sh aarch64 ./sysroot base
```

### Variants

If you want to build a sysroot containing extra libraries, you can build a variant. E.g. the X11 and a gcc version to override the default (13.4.0)

```shell
./sysroot/build.sh x86_64 ./sysroot X11 8.4.0
```
