# Runs every payload ELF through the sandbox's own loader — what
# tests.deps approximates without bubblewrap. Run on a real host:
#
#     nix build .#tsuki.zcode.tests.ldd && ./result/bin/zcode-lddcheck
{
    lib,
    buildFHSEnv,
    findutils,
    file,
    writeShellScript,

    unwrapped,
    targetPkgs,
}:

buildFHSEnv {
    pname = "zcode-lddcheck";
    version = "1";

    inherit targetPkgs;
    dieWithParent = false;

    runScript =
        (writeShellScript "zcode-lddcheck-run" ''
            # The loader's error strings are locale-translated.
            export LC_ALL=C
            status=0
            while IFS= read -r -d ''' elf; do
                # Loader --list also covers non-executable ELFs
                # (dlopen()ed .node addons).
                if out="$(/lib64/ld-linux-x86-64.so.2 --list "$elf" 2>&1)"; then
                    if grep -q "not found" <<< "$out"; then
                        echo "MISSING LIBS: $elf" >&2
                        grep "not found" <<< "$out" >&2
                        status=1
                    fi
                else
                    echo "LDD FAILED: $elf" >&2
                    printf '%s\n' "$out" >&2
                    status=1
                fi
            done < <(
                ${lib.getExe findutils} ${unwrapped}/lib/ZCode -type f -print0 |
                while IFS= read -r -d ''' f; do
                    # Skip the deb's foreign-arch addon blobs.
                    if [[ $(${lib.getExe file} -b "$f") == ELF*x86-64* ]]; then
                        printf '%s\0' "$f"
                    fi
                done
            )
            exit $status
        '').outPath;
}
