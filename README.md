# mise-raku

A modern [mise](https://mise.jdx.dev/) Lua plugin for the Raku programming
language. Installs official prebuilt Rakudo with MoarVM and the zef module
manager. No asdf plugin or standalone Lua installation is required.

## Install

```sh
mise plugins install raku https://github.com/fifitrixabelle/mise-raku.git
mise use raku@latest
mise exec -- raku --version
mise exec -- zef --version
```

Or declare the plugin explicitly in `mise.toml`:

```toml
[plugins]
raku = "https://github.com/fifitrixabelle/mise-raku.git"

[tools]
raku = "2026.09"
```

Then run `mise install`. Use a current mise release; development and CI use
mise 2026.10.23. This plugin uses mise's built-in Lua runtime.

If you already installed the archived asdf Raku plugin, replace its plugin
checkout first (installed Raku versions remain on disk):

```sh
mise plugins install --force raku https://github.com/fifitrixabelle/mise-raku.git
```

## Platforms

| Platform | Architecture |
| --- | --- |
| macOS | Apple Silicon (arm64) |
| macOS | Intel (x86_64) |
| Linux with glibc | x86_64 |

Versions are filtered to those with an archive for the current platform.
Linux arm64, Alpine/musl, Windows and source builds are outside the initial
scope. An unsupported platform or unavailable version produces an error.
Older archives may require an older OS; this plugin does not add compatibility
libraries or change the publisher's binary requirements.

Both `bin/` and `share/perl6/site/bin/` are added to PATH so that `raku`, `zef`
and scripts installed by zef are available. Modules installed inside a Rakudo
installation belong to that version; reinstall them when switching versions.

## Releases and verification

Version discovery uses the maintained
[Rakudo release index](https://raw.githubusercontent.com/skaji/rakudo-releases/main/rakudo-releases.v1.csv).
Archives and checksum documents are downloaded from
[rakudo.org](https://rakudo.org/downloads). No release list is hardcoded in the
plugin. When a version has multiple builds, the highest numeric build revision
for the platform is selected. A version pin fixes the Rakudo version; use
`mise.lock` to record the resolved archive and checksum as well.

The plugin requires a matching SHA-256 from the publisher's checksum document;
mise verifies it before extraction. HTTP errors, unexpected index formats and
missing checksums fail the install. Asset URLs must point to `rakudo.org`.
SHA-256 detects corruption; the archive and checksum share a trust source.
The PGP signatures included in checksum documents are **not verified** by this
plugin. Release dates are not supplied by the index, so versions are undated
for mise's release-age settings.

## Development

```sh
lua tests/test.lua
bash tests/smoke.sh          # pinned Rakudo 2026.09
bash tests/smoke.sh latest   # newest binary for this platform
```

Unit tests require Lua 5.1 or newer, with no extra Lua packages. The smoke test
requires mise, Bash, network access and a supported platform. It creates an
isolated temporary mise environment and retains its path for inspection.
It lists releases, installs Rakudo, runs a Raku assertion, and checks zef.
CI runs unit tests on Lua 5.1 and smoke tests on all three supported platforms.

The plugin consists of `metadata.lua`, three hooks, and one shared release
module. Mise handles downloads, checksum verification and extraction.

## License

MIT for this plugin. Rakudo and bundled components retain their own licenses.
