{
    lib,
    stdenv,
    buildGoModule,
    fetchFromGitHub,
    fetchPnpmDeps,
    pnpmConfigHook,
    nodejs,
    pnpm_11,
}:

let
    version = "0.12.0";

    src = fetchFromGitHub {
        owner = "bestruirui";
        repo = "octopus";
        rev = "v${version}";
        sha256 = "sha256-AQxmnSa+YrMCadMXVu8ujO2Ry5Qv9m4q1dgXiY0ToKo=";
    };

    pnpm = pnpm_11;

    web = stdenv.mkDerivation {
        pname = "octopus-web";
        inherit version src;

        pnpmRoot = "web";

        nativeBuildInputs = [
            nodejs
            pnpm
            pnpmConfigHook
        ];

        pnpmDeps = fetchPnpmDeps {
            pname = "octopus-web";
            inherit src pnpm;
            sourceRoot = "source/web";
            fetcherVersion = 4;
            hash = "sha256-J475qwBvMuX0DxDMDmUGZ7U+EfAIGUUiSnUnqLfKD8U=";
        };

        # vite emits to ../static/out (resolved from vite.config.ts)
        buildPhase = /*sh*/ ''
            runHook preBuild

            pushd web
            VITE_APP_VERSION="v${version}" pnpm build
            popd

            runHook postBuild
        '';

        installPhase = ''
            runHook preInstall

            cp -r static/out $out

            runHook postInstall
        '';
    };

in

buildGoModule rec {
    pname = "octopus";
    inherit version src;

    preBuild = ''
        rm -rf static/out
        cp -r ${web} static/out
    '';

    proxyVendor = true;
    vendorHash = "sha256-PSjt5NwUL1A/FJ1jwX6/R8zmDHNNiHfaA3IQbqwtbic=";

    tags = [ "jsoniter" ];
    ldflags = [
        "-X github.com/bestruirui/octopus/internal/conf.Version=v${version}"
    ];

    env.CGO_ENABLED = 0;
    env.GOAMD64 = "v3";

    doCheck = false;

    meta = with lib; {
        homepage = "https://github.com/bestruirui/octopus";
        description = "LLM API aggregation gateway for individuals";
        mainProgram = "octopus";
        license = licenses.agpl3Only;
    };
}
