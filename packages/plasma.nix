lib: prev:

# Workaround for plasma sluggish
# Props to https://github.com/NixOS/nixpkgs/issues/126590

let

    inherit (prev) stdenv;

    xdgData = base: stdenv.mkDerivation {
        name = "${base.pname}-xdg-data-bundle";
        nativeBuildInputs = [ prev.fd ];
        buildInputs = [ base ];
        dontUnpack = true;
        dontFixup = true;
        dontWrapQtApps = true;
        buildCommand = ''
            mkdir -p "$out/share"
            mkdir -p "work"
            IFS=:; for dir in $XDG_DATA_DIRS; do
                if [[ -d "$dir" ]]; then
                    cp -rv "$dir/." "work"
                    chmod -R u+w "work"
                fi
            done
            rm -rv "work/locale"
            rm -rv "work/doc"
            rm -rv "work/man"
            cp -rv "work/." "$out/share"
        '';
    };

    undoWrap = base: base.overrideAttrs (old: {
        preFixup = ''
            for index in "''${!qtWrapperArgs[@]}"; do
                if [[ ''${qtWrapperArgs[$((index+0))]} == "--prefix" ]] \
                && [[ ''${qtWrapperArgs[$((index+1))]} == "XDG_DATA_DIRS" ]]
                then
                    # --prefix
                    unset -v "qtWrapperArgs[$((index+0))]"
                    # XDG_DATA_DIRS
                    unset -v "qtWrapperArgs[$((index+1))]"
                    # :
                    unset -v "qtWrapperArgs[$((index+2))]"
                    # <path>
                    unset -v "qtWrapperArgs[$((index+3))]"
                fi
            done
            qtWrapperArgs=("''${qtWrapperArgs[@]}")
            qtWrapperArgs+=(--prefix XDG_DATA_DIRS : "${xdgData base}/share")
            qtWrapperArgs+=(--prefix XDG_DATA_DIRS : "$out/share")
        '';
    });

in

prev.kdePackages.overrideScope (_: old: {
    plasma-workspace = undoWrap old.plasma-workspace;
})
