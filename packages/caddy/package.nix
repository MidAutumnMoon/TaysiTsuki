{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,

    stdenvNoCC,
    installShellFiles,
}:

let

    # Explaination of The Dark Art
    #
    # Caddy's "main.go" roughly has following structure, and
    # plugins are added by appending urls into the import block.
    #
    #   package main
    #
    #   import (
    #       caddycmd "<dep>"
    #       _ "<dep>"
    #   )
    #
    #   func main()
    #
    # Upon closer observation, as the closing ")" is on its own line,
    # prepending contents to ")" will be inside the import block.
    #
    # This is done using sed magic: "/<reg>/i<content>"
    #                                       ^ prepend
    addPluginsCmd =
        [
            "github.com/caddy-dns/cloudflare"
        ]
        |> map ( name: '' sed -i '/^)$/i_ "${name}"' "cmd/caddy/main.go" '' )
        |> lib.concatStringsSep "\n";

in

buildGoLatestModule rec {

    pname = "caddy";
    version = "2.10.2";

    src = fetchFromGitHub {
        owner = "caddyserver";
        repo = "caddy";
        tag = "v${version}";
        hash = "sha256-KvikafRYPFZ0xCXqDdji1rxlkThEDEOHycK8GP5e8vk=";
    };

    # needs proxyVendor since go.sum is modified on the fly
    proxyVendor = true;
    vendorHash = "sha256-WQ6eS6/v1g4aOo6m6P3UpeYKldUdHPRf4qrx9/pn8UI=";

    outputs = [
        "out"
        "man"
    ];

    subPackages = [ "cmd/caddy" ];

    doCheck = false;
    env.GOAMD64 = "v2";
    env.CGO_ENABLED = 0;
    env.GOEXPERIMENT = "greenteagc";

    nativeBuildInputs = [ installShellFiles ];

    ldflags = [
        "-s" "-w"
        "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
    ];

    # See https://github.com/caddyserver/caddy/blob/master/.goreleaser.yml
    tags = [
        "nobadger"
        "nomysql"
        "nopgx"
    ];

    preBuild = ''
        ${addPluginsCmd}
        go mod tidy -v
    '';

    postInstall =
        with stdenvNoCC;
        lib.optionalString ( buildPlatform.canExecute hostPlatform ) /* sh */ ''
            "$out/bin/caddy" manpage --directory "manpages"
            installManPage "manpages"/*
            installShellCompletion --cmd caddy \
                --bash <($out/bin/caddy completion bash) \
                --fish <($out/bin/caddy completion fish) \
                --zsh <($out/bin/caddy completion zsh)
        '';

    meta = {
        homepage = "https://caddyserver.com";
        license = lib.licenses.asl20;
        mainProgram = "caddy";
    };

}
