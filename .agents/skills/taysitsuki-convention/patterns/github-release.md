Use `stdenv.mkDerivation` + `autoPatchelfHook`.

Helper function for fetching a single file from GitHub release:

```nix
src = tsuki.fetchGitHubRelease {
    owner = "...";
    repo = "...";
    tag = "${version}";
    file = "example-linux-x86_64.tar.gz";
    hash = "sha256-...";
};
```
