lib:


let

    inherit ( builtins )
        isAttrs
    ;

in

{

    # flatMod :: attrset -> attrset
    #
    # NixOS module but the "config" field is flattened.
    #
    #
    # Normal module looks like this:
    #
    #   {
    #       imports = [ ... ];
    #       options = { ... };
    #       config = {{{{ nested hell no escape help me }}}};
    #   }
    #
    # when "config" field flattened:
    #
    #   {
    #       imports = [ ... ];
    #       options = { ... };
    #       {{ still hell }}
    #       {{ but I feel better }}
    #   }
    #
    # It reduces the nested madness by 1, and it's huge.
    #
    flatMod = body:
        assert isAttrs body;
        {
            options = body.options or {};
            imports = body.imports or [];
            disabledModules = body.disabledModules or [];
            meta = body.meta or {};
            config = removeAttrs body
                [ "options" "imports" "disabledModules" "meta" ];
        };

}
