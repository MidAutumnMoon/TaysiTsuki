{
    fish
}:

fish.overrideAttrs (old: {
    patches = old.patches ++ [
        ./0001-wildcard-no-trailing-slash-for-symlink-to-dir-comple.patch
        ./0002-highlight-add-fish_color_symlink.patch
        ./0003-docs-add-FORK-NOTES.md.patch
        ./0004-wildcard-no-space-after-slash-less-symlink-completio.patch
    ];

    postPatch = old.postPatch + ''
        # Our symlink patch modfies the output
        rm tests/checks/cd.fish
    '';

    buildNoDefaultFeatures = true;
    buildFeatures = [ "embed-manpages" ];

})
