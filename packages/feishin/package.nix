{
    lib,
    feishin,
    pkgs,
    symlinkJoin,
}:

let

    feishinBinE = lib.useElectronBin pkgs feishin;
    exeName = feishinBinE.meta.mainProgram;

in

symlinkJoin {
    name = "feishin";
    paths = [
        feishinBinE
    ];

    postBuild = ''
        mv "$out/bin/${exeName}" "$out/bin/.${exeName}-unwrapped"

        cat > "$out/bin/${exeName}" << 'EOF'
        #!/usr/bin/env bash
        # AI: used AI to write the variable substitution
        export http_proxy="''${http_proxy/socks5:/http:}"
        export https_proxy="''${https_proxy/socks5:/http:}"
        export all_proxy="''${all_proxy/socks5:/http:}"
        exec "$(dirname "$0")/.${exeName}-unwrapped" "$@"
        EOF

        chmod +x "$out/bin/${exeName}"
    '';
}
