# setup-bynk

Install the [Bynk](https://github.com/accuser/bynk) toolchain — `bynkc`, the
`bynk` driver, and `bynkc-lsp` — on a GitHub Actions runner and add it to
`PATH`. Downloads the prebuilt release archive for the runner's OS/arch, verifies
it against the release `SHA256SUMS`, and caches it in the Actions tool cache.

Supported runners: Linux (x86_64, aarch64), macOS (x86_64, aarch64), Windows
(x86_64). No Rust toolchain is required.

## Usage

```yaml
- uses: bynk-lang/setup-bynk@v1
  with:
    version: latest        # or an exact version like 0.107.0
- run: bynkc --version
```

Pin an exact version for reproducible CI:

```yaml
- uses: bynk-lang/setup-bynk@v1
  with:
    version: 0.107.0
```

## Inputs

| Input          | Default        | Description |
| -------------- | -------------- | ----------- |
| `version`      | `latest`       | Exact version (`0.107.0` / `v0.107.0`) or `latest`. |
| `repository`   | `accuser/bynk` | The `owner/name` repo that publishes Bynk releases. |
| `components`   | `""`           | Space-separated extras to keep (`lsp`). All binaries install regardless. |
| `github-token` | `${{ github.token }}` | Token for API/download calls (avoids rate limits). |

## Outputs

| Output      | Description |
| ----------- | ----------- |
| `version`   | The resolved version installed, e.g. `v0.107.0`. |
| `bindir`    | Absolute path to the installed binaries. |
| `cache-hit` | `true` when restored from the tool cache. |

## Notes

- The action expects release assets named `bynk-<version>-<target>.(tar.gz|zip)`
  plus a `SHA256SUMS` manifest — the layout produced by the Bynk `release.yml`.
- `repository` defaults to `accuser/bynk`. If the canonical release repository
  moves under the `bynk-lang` org, update this default (or set the input).
- Before publishing, re-pin `actions/cache` in `action.yml` to a commit SHA.

## License

Licensed under either of [MIT](LICENSE-MIT) or [Apache-2.0](LICENSE-APACHE) at
your option.
