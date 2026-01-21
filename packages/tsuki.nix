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
                    throw "Failed to validate \"${it.attr}\""
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
                throw "Duplicated attrs found";

    tsuki = name: "tsuki.${name}";

    # Predefined groups.
    gs = {
        go_1 = "Go_1";
        go_2 = "Go_2";
        small_1 = "Small_Trivial_1";
        rust_1 = "Rust_1";
        kernel = "Cachy_Kernel";
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
        group = gs.small_1;
        update = {
            pinned = true;
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
            unstable_branch = true;
        };
    }
    {
        attr = "zram-generator";
        group = gs.rust_1;
    }
    {
        attr = "sudo-rs";
        group = gs.rust_1;
    }

    #
    # Cachyos Kernel
    #
    {
        attr = tsuki "cachyos.kernel";
        group = gs.kernel;
    }
    {
        attr = tsuki "cachyos.kernel-patches-updater";
        group = gs.kernel;
        update.unstable_branch = true;
    }
    {
        attr = tsuki "cachyos.kernel-config-updater";
        group = gs.kernel;
        update.unstable_branch = true;
    }

    #
    # others to make sure being cached
    #
    { attr = "nixd"; group = "Nixd"; }
    { attr = "lix"; group = "Lix"; }
    { attr = "colmena"; group = "Colmena"; }
    { attr = tsuki "zellij"; group = "Zellij"; }


]

