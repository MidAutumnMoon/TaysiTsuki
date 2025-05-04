# frozen_string_literal: true

class Array
    def tsukify
        abort "Some item are not String" unless all? { it in String }
        map { "tsuki.#{it}" }
    end
end

{

    small_thing1:
        %w[
            fastfetchMinimal
            metacubexd
            vuetorrent_teapot
        ].tsukify + %w[
            unrar
        ],

    small_thing2: %w[
        nixd
        neovim_teapot
        ruby_teapot.with_preferred_gems
        ruby_teapot.rubocop
        rust-analyzer_teapot
    ],

    # Go programs are typically really fast to build
    go_things:
        %w[
            caddy
            mihomo
        ].tsukify + %w[
            sops-install-secrets
        ],

    prvn_bundle: %w[
        shadowsocks
        hysteria_teapot
        prvn-pkgs.ssserver
        prvn-pkgs.hysteria
        prvn-pkgs.dnscrypt
    ].tsukify,

    # Some heavy rust things
    colmena: %w[colmena],
    inori: %w[inori],

}
