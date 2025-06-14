lib:


let

    inherit ( lib.filesystem )
        pathIsDirectory
    ;

    inherit ( lib.fileset )
        fileFilter
        toList
    ;

in

{


    # listAllModules :: path -> [ path ]
    #
    # Alllll the modules.
    #
    listAllModules = entry:
      assert pathIsDirectory entry;
      fileFilter ( file: file.name == "module.nix" ) entry |> toList;

}
