let

    inherit (builtins)
        all
        hasAttr
        isString
        foldl'
        elem
        length
        mapAttrs
        attrValues
        isList
        concatMap
    ;

    flatten = x:
        if isList x then
            concatMap flatten x
        else
            [ x ];

    # Roughly make sure the output is of expected shape.
    # This reduce the work need to be done by the maintenace tool.
    withValidate =
        let
            validateOne = one:
                all (p: hasAttr p one && isString one.${p}) ["attr" "group"];
        in
            map (it:
                if validateOne it then
                    it
                else
                    builtins.throw "Failed to validate \"${it.attr}\""
            );

    allUnique = packages:
        let
            uniq = foldl'
                (acc: one:
                    if elem one.attr acc then acc else acc ++ [ one.attr ]
                ) [];
        in
            if length packages == length (uniq packages) then
                packages
            else
                builtins.throw "Duplicated attrs found";

    tsuki = name: "tsuki.${name}";

    # Predefined groups.
    gs = {
        go_1 = "Go_1";
        go_2 = "Go_2";
        small_1 = "Small_Trivial_1";
        rust_1 = "Rust_1";
    };

in

allUnique <| withValidate <|

[
    #
    # small 1
    #
    {
        attr = tsuki "adblocklist";
        group = gs.small_1;
        update = {};
    }
    {
        attr = tsuki "metacubexd";
        group = gs.small_1;
        update = {};
    }
    {
        attr = tsuki "monaspace";
        group = gs.small_1;
        update = {};
    }
    {
        attr = tsuki "peerbanhelper";
        group = gs.small_1;
        update = {};
    }
    {
        attr = tsuki "rust.rust-analyzer";
        group = gs.small_1;
        update = {};
    }
    {
        attr = tsuki "zed";
        group = gs.small_1;
        update = {};
    }
    {
        attr = tsuki "deno";
        group = gs.small_1;
        update = {};
    }

    #
    # go 1
    #
    {
        attr = tsuki "caddy";
        group = gs.go_1;
        update = {};
    }
    {
        attr = tsuki "dnscrypt";
        group = gs.go_1;
        update = {};
    }
    {
        attr = "sops-install-secrets";
        group = gs.go_1;
    }
    {
        attr = tsuki "hysteria";
        group = gs.go_1;
        update.version_regex = "app/v(.*)";
    }
    {
        attr = tsuki "avahi2dns";
        group = gs.go_1;
        update = {};
    }

    #
    # go 2
    #
    {
        attr = tsuki "coredns";
        group = gs.go_2;
        update = {};
    }
    {
        attr = tsuki "opentofu";
        group = gs.go_2;
    }
    {
        attr = tsuki "sing-box";
        group = gs.go_2;
        update = {
            preview_release = true;
            unstable_branch = true;
        };
    }

    #
    # rust 1
    #
    {
        attr = tsuki "shadowsocks";
        group = gs.rust_1;
        update = {};
    }
    {
        attr = tsuki "mimic-cloud-init";
        group = gs.rust_1;
    }
    {
        attr = tsuki "inori";
        group = "Inori";
        update = {
            pinned = true;
            unstable_branch = true;
        };
    }
    {
        attr = "zram-generator";
        group = gs.rust_1;
    }

    #
    # others to make sure being cached
    #
    { attr = "nixd"; group = "Nixd"; }
    { attr = "lix"; group = "Lix"; }
    { attr = "colmena"; group = "Colmena"; }
    { attr = tsuki "zellij"; group = "Zellij"; }
    {
        attr = "linuxPackages_cachyos.kernel";
        group = "CachyKernel";
    }
    {
        attr = "linuxPackages_cachyos-lts.kernel";
        group = "CachyKernelLTS";
    }
]

++

# KDE packages, a lot of them are not cached on
# unstable small after a staging-next merge
(
    let
        kde = map (name: "kdePackages.${name}");
        gen = o:
            mapAttrs
                (name: map (v: { attr = v; group = name; })) o
            |> attrValues
            |> flatten
        ;
    in
        gen {
            "KDE_1" =
                ["telegram-desktop"] ++ kde [
                    "kwin" "sddm" "systemsettings"
                ];
            "KDE_2" = kde [
                "spectacle" "okular" "kinfocenter"
                "xdg-desktop-portal-kde" "dolphin"
            ];
            "KDE_3" = kde [
                "plasma-desktop" "konsole"
                "kate" "kwalletmanager"
            ];
        }
)

# $ nix-instantiate --eval --json --strict tsuki.nix
