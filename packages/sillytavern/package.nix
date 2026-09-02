{
    lib,
    sillytavern,
    tsuki,
}:

let
    serverPlugins = [
        tsuki.sillytavern-token-estimate
        tsuki.sillytavern-openai-response
    ];
in
sillytavern.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + lib.concatMapStringsSep "\n" (p:
        # Copy rather than symlink: the plugin resolves SillyTavern's src/ via
        # `path.resolve(__dirname, '..', '..', 'src', ...)`. If symlinked, Node
        # realpaths __dirname to the plugin's own store path and the relative
        # navigation escapes the sillytavern tree. A real copy keeps __dirname
        # inside plugins/<pname>/ where upstream expects it.
        ''cp -r "${p}" "$out/lib/node_modules/sillytavern/plugins/${p.pname}"''
    ) serverPlugins;
})
