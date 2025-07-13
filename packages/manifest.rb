# frozen_string_literal: true

class Array
    def tsukify
        abort "Some item are not String" unless all? { it in String }
        map { "tsuki.#{it}" }
    end
    def kde_package
        abort "Some item are not String" unless all? { it in String }
        map { "kdePackages.#{it}" }
    end
end

{

    small_thing1:
        %w[
            metacubexd
            adblocklist
        ].tsukify + %w[
            fastfetchMinimal
            unrar
        ],

    small_thing2:
        %w[
            neovim
            ruby.with_preferred_gems
            ruby.rubocop
            rust.rust-analyzer
        ].tsukify + %w[
            nixd
        ],

    # Go programs are typically really fast to build
    go_things:
        %w[
            caddy
            dnscrypt
            coredns
        ].tsukify + %w[
            sops-install-secrets
        ],

    # ...but some are not
    go_things2:
        %w[
            opentofu
        ].tsukify,

    prvn_bundle: %w[
        shadowsocks
        hysteria
        prvn-pkgs.ssserver
        prvn-pkgs.hysteria
        prvn-pkgs.dnscrypt
        prvn-pkgs.sing-box
    ].tsukify,

    lix: %w[lix],

    # Some heavy rust things
    colmena: %w[colmena],
    inori: %w[inori].tsukify,
    wezterm: %w[wezterm],

    kde_things1:
        %w[
            mesa
            telegram-desktop
            tsuki.qimgv
        ] + %w[
            kwin sddm plasma-pa systemsettings drkonqi kscreen kde-cli-tools
        ].kde_package,

    kde_things2:
        %w[mesa] + %w[
            spectacle okular kinfocenter powerdevil
            dolphin xdg-desktop-portal-kde
        ].kde_package,

    kde_things3:
        %w[mesa] + %w[
            plasma-workspace plasma-desktop kdeplasma-addons
        ].kde_package,

    strawberry: %w[tsuki.strawberry],

}
