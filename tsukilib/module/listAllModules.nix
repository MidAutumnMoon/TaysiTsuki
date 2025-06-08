lib:


let

    inherit ( builtins )
        baseNameOf
        filter
    ;

    inherit ( lib.filesystem )
        pathIsDirectory
        listFilesRecursive
    ;

    _isModule = path:
        baseNameOf path == "module.nix";

in

{


    # listAllModules :: path -> [ path ]
    #
    # Alllll the modules.
    #
    listAllModules = entry:
      assert pathIsDirectory entry;
      filter _isModule ( listFilesRecursive entry );

}
