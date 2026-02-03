# Rust Build Action

A GitHub Action for building Rust projects with musl or GNU libc targets on x86_64 Linux.

## Features

- Build Rust projects with musl, GNU libc, or cargo-zigbuild targets
- Support for cargo-zigbuild to target specific glibc versions
- Support for custom Rust versions
- Install additional system dependencies
- Run custom commands after dependency installation
- Configurable APT mirrors for faster package installation
- Debug mode for detailed build logs
- Returns the release directory path for easy artifact collection

## Usage

### Basic Example

```yaml
- name: Build Rust Project
  uses: arloor/rust_musl_action@latest
  with:
    path: my-rust-project
    args: --no-default-features
```

### Example with cargo-zigbuild (for old glibc compatibility)

```yaml
- name: Build with cargo-zigbuild
  id: build
  uses: arloor/rust_musl_action@latest
  with:
    path: my-rust-project
    use_zigbuild: true
    zig_version: 0.15.2
    zig_glibc_version: 2.17 # Target glibc 2.17 for maximum compatibility
    args: --no-default-features

- name: Upload Artifacts
  uses: actions/upload-artifact@v3
  with:
    name: release-binaries
    path: ${{ steps.build.outputs.release_dir }}
```

### Advanced Example with musl

```yaml
- name: Checkout rust_http_proxy
  uses: actions/checkout@v4
  with:
    repository: arloor/rust_http_proxy
    path: rust_http_proxy

- name: Test Local Action
  id: build
  uses: arloor/rust_musl_action@latest
  with:
    path: rust_http_proxy
    use_musl: true
    musl_version: 1.2.5
    extra_deps: cmake zlib1g-dev libelf-dev clang pkg-config make
    after_install: |
      apt-get remove -y gcc
      apt-get install -y gcc-10
      # find / -name libelf.a
      # find / -name libbpf.a
      # find / -name libz.a
      export LIBBPF_SYS_LIBRARY_PATH=/usr/lib:/usr/lib64:/usr/lib/x86_64-linux-gnu
      echo -e "\e[31mLIBBPF_SYS_LIBRARY_PATH=$LIBBPF_SYS_LIBRARY_PATH\e[0m"
    args: -p rust_http_proxy --no-default-features --features aws_lc_rs,bpf_static
    debug: true
- name: Print Output
  id: output
  run: |
    echo "release_dir: ${{ steps.build.outputs.release_dir }}"
    ls -lh ${{ steps.build.outputs.release_dir }}

- name: Upload Artifacts
  uses: actions/upload-artifact@v3
  with:
    name: release-binaries
    path: ${{ steps.build.outputs.release_dir }}
```

## Inputs

| Input               | Description                                                                            | Required | Default  |
| ------------------- | -------------------------------------------------------------------------------------- | -------- | -------- |
| `path`              | Relative path under $GITHUB_WORKSPACE to place the repository                          | Yes      | `""`     |
| `args`              | Custom arguments passed to `cargo build` or `cargo zigbuild`                           | Yes      | `""`     |
| `use_musl`          | Whether to use musl target (`true` or `false`). Mutually exclusive with `use_zigbuild` | Yes      | `false`  |
| `use_zigbuild`      | Whether to use cargo-zigbuild (`true` or `false`). Mutually exclusive with `use_musl`  | Yes      | `false`  |
| `rust_version`      | Rust version to install (e.g., `1.76.0`). If empty, uses latest                        | Yes      | `""`     |
| `musl_version`      | musl version to compile and install (e.g., `1.2.5`)                                    | Yes      | `1.2.5`  |
| `zig_version`       | zig version for cargo-zigbuild (e.g., `0.15.2`)                                        | Yes      | `0.15.2` |
| `zig_glibc_version` | Target glibc version for cargo-zigbuild (e.g., `2.17`, `2.27`)                         | Yes      | `2.17`   |
| `extra_deps`        | Extra apt dependencies to install, separated by spaces (e.g., `libssl-dev libpq-dev`)  | Yes      | `""`     |
| `after_install`     | Shell commands to run after installing dependencies                                    | Yes      | `""`     |
| `debug`             | Enable debug mode for verbose output (`true` or `false`)                               | Yes      | `false`  |
| `apt_mirror`        | Custom APT mirror to use (e.g., `mirrors.mit.edu`)                                     | No       | `""`     |
| `rust_flags`        | Custom RUSTFLAGS (e.g., `"-C target-feature=+crt-static"`)                             | No       | `""`     |

## Outputs

| Output        | Description                                                                 |
| ------------- | --------------------------------------------------------------------------- |
| `release_dir` | The directory path containing the compiled release binaries (ends with `/`) |

The release directory will be:

- `{path}/target/x86_64-unknown-linux-musl/release/` when using musl
- `{path}/target/x86_64-unknown-linux-gnu/release/` when using GNU libc

## Build Targets

- **musl target**: `x86_64-unknown-linux-musl` - produces static binaries
- **GNU target**: `x86_64-unknown-linux-gnu` - produces dynamic binaries
- **zigbuild target**: `x86_64-unknown-linux-gnu.{glibc_version}` - produces binaries compatible with specific glibc versions (e.g., `x86_64-unknown-linux-gnu.2.17`)

## How It Works

This action uses a Docker container based on Ubuntu Focal (20.04) that:

1. Configures APT mirror (if specified)
2. Installs required dependencies (`curl`, `gcc`, and any extra dependencies)
3. Installs Rust toolchain with the specified version
4. If using zigbuild: downloads and installs zig, then installs cargo-zigbuild
5. If using musl: compiles and installs musl-gcc from source
6. Adds the appropriate Rust target (musl or GNU)
7. Runs any custom `after_install` commands
8. Builds the Rust project with `cargo build --release`, `cargo zigbuild --release`, or musl build
9. Outputs the release directory path

## Development and Testing

This action is tested in the [Auto-release workflow](.github/workflows/auto-release.yml), which:

- Builds a real Rust project with complex dependencies
- Tests both musl and GNU targets
- Publishes the `latest` release tag with built artifacts
- Validates the action works end-to-end

## References

- [GitHub Actions: Creating a Docker container action](https://docs.github.com/en/actions/tutorials/use-containerized-services/create-a-docker-container-action)
- [GitHub Actions: Metadata syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/metadata-syntax)
- [GitHub Actions: Hello World Docker Action Example](https://github.com/actions/hello-world-docker-action)
- [Example Usage in rust_http_proxy](https://github.com/arloor/rust_http_proxy/blob/master/.github/workflows/rust.yml)

## License

This project is open source and available under the MIT License.

## Author

Created by [arloor](https://github.com/arloor)
