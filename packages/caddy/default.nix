{
    lib,
    buildGoModule,
    fetchFromGitHub,

    stdenvNoCC,
    installShellFiles,
}:

let

    # Explain of The Dark Art
    #
    # caddy's "main.go" file looks like this:
    #
    #   package main
    #
    #   import (
    #       caddycmd "url..."
    #       _ "url"
    #   )
    #
    #   func main
    #
    # Upon closer observation, we can notice that the closing ")"
    # of "import" statment is on its own line, which means by prepending
    # to the closing ")", content can be placed right inside the "import" statment.
    #
    # This part is done by using some sed magics: '/<reg>/i<content>'
    #                                                     ^ this flag
    plugins = [
        "github.com/caddy-dns/cloudflare"
    ]
    |> map ( name: '' sed -i '/^)$/i_ "${name}"' "cmd/caddy/main.go" '' )
    |> lib.concatStringsSep "\n"
    ;

in

buildGoModule rec {

    pname = "caddy";
    version = "2.9.1";

    src = fetchFromGitHub {
        owner = "caddyserver";
        repo = "caddy";
        tag = "v${version}";
        hash = "sha256-XW1cBW7mk/aO/3IPQK29s4a6ArSKjo7/64koJuzp07I=";
    };

    # needs proxyVendor since go.sum is modified on the fly
    proxyVendor = true;
    vendorHash = "sha256-FhxmBWU7in8cNaclxVUSWcnroSeFzR8/qcXJgjtRKFA=";

    subPackages = [ "cmd/caddy" ];

    doCheck = false;
    env.GOAMD64 = "v3";
    env.CGO_ENABLED = 0;

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
        ${plugins}
        go mod tidy -v
    '';

    postInstall = let
        canExec = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
    in lib.optionalString canExec /* sh */ ''
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
