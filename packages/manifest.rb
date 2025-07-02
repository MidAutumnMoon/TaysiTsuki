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
            vuetorrent
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
            sing-box
            opentofu
            coredns
        ].tsukify + %w[
            sops-install-secrets
        ],

    prvn_bundle: %w[
        shadowsocks
        hysteria
        prvn-pkgs.ssserver
        prvn-pkgs.hysteria
        prvn-pkgs.dnscrypt
    ].tsukify,

    lix: %w[lix],

    # Some heavy rust things
    colmena: %w[colmena],
    inori: %w[inori].tsukify,

    kde_things1:
        %w[
            mesa
            telegram-desktop
        ] + %w[
            plasma-workspace kwin sddm plasma-pa systemsettings
            drkonqi kscreen kde-cli-tools
        ].kde_package,

    kde_things2:
        %w[mesa] + %w[
            spectacle okular kinfocenter powerdevil
            dolphin xdg-desktop-portal-kde
        ].kde_package,

}
