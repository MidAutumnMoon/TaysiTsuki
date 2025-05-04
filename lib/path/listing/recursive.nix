lib:


let

    inherit ( builtins )
        attrNames
        concatMap
        readDir
    ;

    inherit ( lib.tsuki.path )
        isDir
    ;


    # onlyDirs :: path -> [ string ]
    #
    # Hand rolling "lib.filterAttrs" because
    # using it casts a slight performance penalty.
    #
    _listOnlyDirs = parent:
        let children = readDir parent; in
        concatMap ( childname:
            if children.${childname} == "directory" then
                [ childname ]
            else
                []
        ) ( attrNames children );


    # listDirs :: path -> [ path ]
    #
    # Construct "path"s from child dir names.
    #
    # Similar to _listOnlyDirs, not using
    # "lib.path.append" because of performance concers.
    #
    listOnlyDirs = entry:
        map ( n: entry + ( "/" + n ) ) ( _listOnlyDirs entry );


    # _listAllDirs :: path -> [ path ]
    #
    # Unsafe (no type assertion) "listAllDirs"
    # in order to increase the speed.
    #
    _listAllDirs = entry:
        [ entry ] ++ (
            concatMap _listAllDirs ( listOnlyDirs entry )
        );

in

{

    # listAllDirs :: path -> [ path ]
    #
    # Traverse the $entry recursively
    # and collect every directories inside it.
    #
    # Benchmark: avg. 180ms when testing against nixpkgs,
    # (.git directory removed) on kernel 6.1 & btrfs.
    #
    # Not too shabby :)
    #
    listAllDirs = entry:
        assert isDir entry;
        _listAllDirs entry;


    # listAllFiles :: path -> [ path ]
    listAllFiles = entry:
        assert isDir entry;
        lib.filesystem.listFilesRecursive entry;

}
