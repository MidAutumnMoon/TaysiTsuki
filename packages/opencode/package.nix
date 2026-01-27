{
    opencode,
    symlinkJoin,
    runtimeShell,
}:

let
    exeName = opencode.meta.mainProgram;
in

symlinkJoin {
    name = "opencode";

    paths = [
        opencode
    ];

    postBuild = ''
        mv "$out/bin/${exeName}" "$out/bin/.${exeName}-before-proxy"

        cat > "$out/bin/${exeName}" << 'EOF'
        #!${runtimeShell}
        # AI: used AI to write the variable substitution
        export http_proxy="''${http_proxy/socks5:/http:}"
        export https_proxy="''${https_proxy/socks5:/http:}"
        export all_proxy="''${all_proxy/socks5:/http:}"
        exec "$(dirname "$0")/.${exeName}-before-proxy" "$@"
        EOF

        chmod +x "$out/bin/${exeName}"
    '';
}
