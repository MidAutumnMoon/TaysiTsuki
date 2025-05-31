lib:

let

    inherit ( builtins )
        isPath
        readFileType
    ;

in

{

    # isDir:: path -> bool
    #
    # A filesystem trick is used.
    #
    isDir =
        path: isPath path && ( readFileType path ) == "directory";

}
