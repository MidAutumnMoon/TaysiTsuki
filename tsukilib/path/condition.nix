lib:

let

    inherit ( builtins )
        isPath
        readFileType
    ;

in

{

    # isDir:: path -> bool
    isDir =
        path: isPath path && ( readFileType path ) == "directory";

}
