# mise-raku

Build `fifitrixabelle/mise-raku`, a modern mise-only Lua tool plugin. The user
selected the Lua approach over maintaining the old asdf Bash plugin.

Install official prebuilt Rakudo/MoarVM archives, including zef, for macOS
arm64/x86_64 and Linux x86_64 (glibc). Discover versions from the maintained
skaji release index; select the highest build revision for a version/platform.
Return both executable directories through EnvKeys. Delegate downloading,
SHA-256 verification and extraction to mise. Fail on missing builds, malformed
metadata, missing checksums and HTTP errors. Restrict asset URLs to rakudo.org.

No source builds, asdf compatibility, external Lua dependencies or custom
download/extraction machinery. No fabricated release dates. Checksums protect
integrity; this version does not verify the publisher's PGP signatures.

Tests cover release filtering, rebuild selection, metadata rejection, checksum
filename matching and hook output. CI runs unit tests plus real installations
on the three supported platforms. Verify locally on Apple Silicon before
creating the GitHub repository. Prepare the repository outside examples.
