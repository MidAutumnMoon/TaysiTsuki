# TäysiTsuki

<sub>P</sub>i<sup>v</sup>o<sub>t </sub>A<sub>w</sub>a<sup>y</sup>

## Use Tsuki's Binary Cache

Tsuki's binary cache is hosted using [Cachix](https://www.cachix.org/),

1. Add `https://nuirrce.cachix.org` to substituter list
2. Add pubkey `nuirrce.cachix.org-1:KQWa6ZfDkMPXeDiUpmyDhNw4CmgybPyeVklmi/1Rtqk=`

## Notes on Setup GitHub Actions

### Necessary Permission
1. Find `Actions/General` in Settings.
2. Select `Read and write permissions` under Workflow permissions.
3. Enable `Allow Github Actions to create...pull requests`.

### Setup Cachix
1. Obtain the token from Cachix dashboard.
2. Put the token in a secret named `CACHIX_AUTH_TOKEN`.
