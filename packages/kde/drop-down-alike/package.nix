{
    lib,
    runCommand,
}:

{

    resource_class,
    shortcut ? "Meta+`",

    __config ? {
        inherit resource_class shortcut;
    },

    __metadata ? {
        KPlugin = {
            Name = "Drop Down (Alike)";
            Authors = [ { Name = "MidAutumnMoon"; } ];
            Description = "Drop down any terminal";
            Icon = "preferences-system-windows-script-test";
            Id = "im.418.drop-down-alike";
            License = "GPLv3";
            Version = "1.0";
        };
        KPackageStructure = "KWin/Script";
        X-Plasma-API = "javascript";
        X-Plasma-MainScript = "main.js";
        X-KWin-Border-Activate = "true";
    },

}:

runCommand "drop-down-alike" { } ''

    declare -r dest="$out/share/kwin/scripts/${__metadata.KPlugin.Id}"
    mkdir -pv "$dest"

    declare -r configJson="config.json"
    declare -r metadataDst="$dest/metadata.json"
    declare -r scriptDst="$dest/contents/code/${__metadata.X-Plasma-MainScript}"
    mkdir -pv "$( dirname $scriptDst )"

    printf '%s' '${builtins.toJSON __metadata}' > "$metadataDst"

    # Appearently kwin script engine doesn't have atob/btoa
    printf '%s' \
        '${builtins.toJSON __config |> lib.escape ["\"" "`"]}' \
        > "$configJson"

    substitute "${./main.js}" "$scriptDst" \
        --subst-var-by "config" "$( < $configJson )"

''

# vim: nowrap
