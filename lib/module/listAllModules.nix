lib:


let

    inherit ( builtins )
        filter
    ;

    inherit ( lib.tsuki.path )
        isDir
        listAllDirs
    ;

    inherit ( lib.tsuki.module )
        isModule
    ;

in

{


    # listAllModules :: path -> [ path ]
    #
    # Alllll the modules.
    #
    listAllModules = entry:
      assert isDir entry;
      filter isModule ( listAllDirs entry );

}
