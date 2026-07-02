<!-- Generated with Stardoc: http://skydoc.bazel.build -->

This module provides the definitions for registering a GCC toolchain for C and C++.

<a id="gcc_register_toolchain"></a>

## gcc_register_toolchain

<pre>
load("@bazel-toolchains//gcc_toolchain:gcc_defs.bzl", "gcc_register_toolchain")

gcc_register_toolchain(<a href="#gcc_register_toolchain-name">name</a>, <a href="#gcc_register_toolchain-target_arch">target_arch</a>, <a href="#gcc_register_toolchain-kwargs">**kwargs</a>)
</pre>

Declares a `gcc_toolchain`.

You should use `gcc_register_toolchain` unless you need to register toolchains manually,
e.g. if you are consuming this repository as a Bzlmod dependency.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="gcc_register_toolchain-name"></a>name |  The name passed to `gcc_toolchain`.   |  none |
| <a id="gcc_register_toolchain-target_arch"></a>target_arch |  The target architecture of the toolchain.   |  none |
| <a id="gcc_register_toolchain-kwargs"></a>kwargs |  The extra arguments passed to `gcc_toolchain`. See `gcc_toolchain` for more info.   |  none |


<a id="gcc_toolchain"></a>

## gcc_toolchain

<pre>
load("@bazel-toolchains//gcc_toolchain:gcc_defs.bzl", "gcc_toolchain")

gcc_toolchain(<a href="#gcc_toolchain-name">name</a>, <a href="#gcc_toolchain-binary_prefix">binary_prefix</a>, <a href="#gcc_toolchain-extra_asmflags">extra_asmflags</a>, <a href="#gcc_toolchain-extra_cflags">extra_cflags</a>, <a href="#gcc_toolchain-extra_cxxflags">extra_cxxflags</a>, <a href="#gcc_toolchain-extra_fflags">extra_fflags</a>,
              <a href="#gcc_toolchain-extra_ldflags">extra_ldflags</a>, <a href="#gcc_toolchain-fincludes">fincludes</a>, <a href="#gcc_toolchain-gcc_version">gcc_version</a>, <a href="#gcc_toolchain-gcc_versions">gcc_versions</a>, <a href="#gcc_toolchain-includes">includes</a>, <a href="#gcc_toolchain-path_to_toolchain">path_to_toolchain</a>,
              <a href="#gcc_toolchain-repo_mapping">repo_mapping</a>, <a href="#gcc_toolchain-target_arch">target_arch</a>, <a href="#gcc_toolchain-target_compatible_with">target_compatible_with</a>, <a href="#gcc_toolchain-target_settings">target_settings</a>,
              <a href="#gcc_toolchain-toolchain_workspace_name">toolchain_workspace_name</a>)
</pre>

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="gcc_toolchain-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="gcc_toolchain-binary_prefix"></a>binary_prefix |  An explicit prefix used by each binary in bin/.   | String | required |  |
| <a id="gcc_toolchain-extra_asmflags"></a>extra_asmflags |  Extra flags for the assembly preprocessor.   | List of strings | optional |  `[]`  |
| <a id="gcc_toolchain-extra_cflags"></a>extra_cflags |  Extra flags for compiling C.   | List of strings | optional |  `[]`  |
| <a id="gcc_toolchain-extra_cxxflags"></a>extra_cxxflags |  Extra flags for compiling C++.   | List of strings | optional |  `[]`  |
| <a id="gcc_toolchain-extra_fflags"></a>extra_fflags |  Extra flags for compiling Fortran.   | List of strings | optional |  `[]`  |
| <a id="gcc_toolchain-extra_ldflags"></a>extra_ldflags |  Extra flags for linking. %workspace% is rendered to the toolchain root path. See https://github.com/bazelbuild/bazel/blob/a48e246e/src/main/java/com/google/devtools/build/lib/rules/cpp/CcToolchainProviderHelper.java#L234-L254.   | List of strings | optional |  `[]`  |
| <a id="gcc_toolchain-fincludes"></a>fincludes |  Extra includes for compiling Fortran. %workspace% is rendered to the toolchain root path.   | List of strings | optional |  `[]`  |
| <a id="gcc_toolchain-gcc_version"></a>gcc_version |  The version of GCC.   | String | optional |  `"13.4.0"`  |
| <a id="gcc_toolchain-gcc_versions"></a>gcc_versions |  A JSON dictionary of GCC versions to their download URLs and SHA256 hashes. The structure is {<gcc_version>: {<target_arch>: {url: <url>, sha256: <sha256>}}}.   | String | optional |  `"{\"11.3.0\":{\"aarch64\":{\"sha256\":\"7e130eec00803790fad1f082c460c761b07508cccaa0c7859ae672ef3cbbab6e\",\"url\":\"https://github.com/sgmenon/bazel-toolchains/releases/download/v1.0.0/toolchain-base-gcc11.3.0-aarch64.tar.xz\"},\"x86_64\":{\"sha256\":\"132f8bd08e07d9ff88b1399973389375d5219b5daa5e7418d23283634d746374\",\"url\":\"https://github.com/sgmenon/bazel-toolchains/releases/download/v1.0.0/toolchain-base-gcc11.3.0-x86_64.tar.xz\"}},\"13.4.0\":{\"aarch64\":{\"sha256\":\"e8021828ea59766c0c57c0d2a5220a027c2aeecb97368a2ee3389b70b2e1d22f\",\"url\":\"https://github.com/sgmenon/bazel-toolchains/releases/download/v1.0.0/toolchain-base-gcc13.4.0-aarch64.tar.xz\"},\"x86_64\":{\"sha256\":\"f019cbb81c082178161a4a4fa818c7c92b43b5732797c6218b4916f604ae21ff\",\"url\":\"https://github.com/sgmenon/bazel-toolchains/releases/download/v1.0.0/toolchain-base-gcc13.4.0-x86_64.tar.xz\"}}}"`  |
| <a id="gcc_toolchain-includes"></a>includes |  Extra includes for compiling C and C++. %workspace% is rendered to the toolchain root path. See https://github.com/bazelbuild/bazel/blob/a48e246e/src/main/java/com/google/devtools/build/lib/rules/cpp/CcToolchainProviderHelper.java#L234-L254.   | List of strings | optional |  `[]`  |
| <a id="gcc_toolchain-path_to_toolchain"></a>path_to_toolchain |  The path to the toolchain files.   | String | optional |  `"toolchain"`  |
| <a id="gcc_toolchain-repo_mapping"></a>repo_mapping |  In `WORKSPACE` context only: a dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.<br><br>For example, an entry `"@foo": "@bar"` declares that, for any time this repository depends on `@foo` (such as a dependency on `@foo//some:target`, it should actually resolve that dependency within globally-declared `@bar` (`@bar//some:target`).<br><br>This attribute is _not_ supported in `MODULE.bazel` context (when invoking a repository rule inside a module extension's implementation function).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  |
| <a id="gcc_toolchain-target_arch"></a>target_arch |  The target architecture this toolchain produces. E.g. x86_64.   | String | required |  |
| <a id="gcc_toolchain-target_compatible_with"></a>target_compatible_with |  contraint_values passed to target_compatible_with of the toolchain. {target_arch} is rendered to the target_arch attribute value, and {compiler_version} is rendered to the major version of the gcc_version attribute value.   | List of strings | optional |  `["@platforms//os:linux", "@platforms//cpu:{target_arch}", "@{toolchain_workspace_name}//platforms:{compiler_version}"]`  |
| <a id="gcc_toolchain-target_settings"></a>target_settings |  config_settings passed to target_compatible_with of the toolchain. {target_arch} is rendered to the target_arch attribute value.   | List of strings | optional |  `[]`  |
| <a id="gcc_toolchain-toolchain_workspace_name"></a>toolchain_workspace_name |  The name given to the gcc-toolchain repository, if the default was not used.   | String | optional |  `"gcc_toolchain"`  |


