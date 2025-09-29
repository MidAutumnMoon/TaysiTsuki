let

    inherit (builtins)
        all
        hasAttr
        isString
        attrValues
        elem
    ;

    # Roughly make sure the output is of expected shape.
    # This reduce the work need to be done by the maintenace tool.
    withValidate =
        let
            validateOne = one:
                # 1. Essential attrs
                all (p: hasAttr p one && isString one.${p}) ["attr" "group"]
                # 2. Use predefined groups
                && elem one.group (attrValues gs)
            ;
        in
            map (it:
                if validateOne it then
                    it
                else
                    builtins.throw "Failed to validate \"${it.attr}\""
            );

    tsuki = name: "tsuki.${name}";

    # Predefined groups.
    gs = {
        go1 = "go_things";
    };

in

withValidate <|

[
    {
        attr = tsuki "hysteria";
        group = gs.go1;
        update.version_regex = "app/v(.*)";
    }
]

# $ nix-instantiate --eval --json --strict tsuki.nix
