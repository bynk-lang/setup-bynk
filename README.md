# setup-bynk

Install the [Bynk](https://github.com/bynk-lang/bynk) toolchain — `bynkc`, the
`bynk` driver, and `bynkc-lsp` — on a GitHub Actions runner and add it to
`PATH`. Downloads the prebuilt release archive for the runner's OS/arch, verifies
it against the release `SHA256SUMS`, and caches it in the Actions tool cache.

Supported runners: Linux (x86_64, aarch64), macOS (x86_64, aarch64), Windows
(x86_64). No Rust toolchain is required.

## Usage

```yaml
- uses: bynk-lang/setup-bynk@v1
  with:
    version: latest        # or an exact version like 0.377.2
- run: bynkc --version
```

Pin an exact version for reproducible CI:

```yaml
- uses: bynk-lang/setup-bynk@v1
  with:
    version: 0.377.2
```

Or keep the pin in a file, so every workflow in the repository reads the same
one and a tool can move it in one place (the org canary's bump pull requests
do):

```yaml
- uses: bynk-lang/setup-bynk@v1
  with:
    version-file: BYNK_VERSION   # holds e.g. 0.377.2
```

## Inputs

| Input          | Default        | Description |
| -------------- | -------------- | ----------- |
| `version`      | `latest`       | Exact version (`0.377.2` / `v0.377.2`) or `latest`. |
| `version-file` | `""`           | A file holding an exact version, such as `BYNK_VERSION`, relative to the workspace. Whitespace around the version is ignored. Use this or `version`, not both. |
| `repository`   | `bynk-lang/bynk` | The `owner/name` repo that publishes Bynk releases. |
| `components`   | `""`           | Space-separated extras to keep (`lsp`). All binaries install regardless. |
| `github-token` | `${{ github.token }}` | Token for API/download calls (avoids rate limits). |

## Outputs

| Output      | Description |
| ----------- | ----------- |
| `version`   | The resolved version installed, e.g. `v0.377.2`. |
| `bindir`    | Absolute path to the installed binaries. |
| `cache-hit` | `true` when restored from the tool cache. |

## Notes

- The action expects release assets named `bynk-<version>-<target>.(tar.gz|zip)`
  plus a `SHA256SUMS` manifest — the layout produced by the Bynk `release.yml`.
- `repository` defaults to `bynk-lang/bynk`. If the canonical release repository
  moves under the `bynk-lang` org, update this default (or set the input).
- `actions/cache` is pinned to a commit SHA (v6.1.0), which runs on Node.js 24
  and needs Actions Runner 2.327.1 or newer on self-hosted runners.

## License

Licensed under either of [MIT](LICENSE-MIT) or [Apache-2.0](LICENSE-APACHE) at
your option.
