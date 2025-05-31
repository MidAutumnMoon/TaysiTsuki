lib:

let

    inherit ( lib )
        filter
        hasAttrByPath
        concatMap
        concatStringsSep
        optionalString
    ;

in {

    # libsToCompilerEnvvars :: [ pkg ] -> bash script string
    #
    # Generate a Bash script, intended to be included in "shellHook",
    # whose purpose is to export CPATH[1] and LIBRARY_PATH[1]
    # by using information provided by "pkg-config" on `libs`.
    #
    # The main benefit is that the need of build system frontend
    # like meson or cmake is elimited when working on tiny prototype
    # projects :P
    #
    # [1]: https://gcc.gnu.org/onlinedocs/gcc/Environment-Variables.html
    libsToCompilerEnvvars = libraries:
        let
            modules = libraries
                |> filter ( hasAttrByPath [ "meta" "pkgConfigModules" ] )
                |> concatMap ( p: p.meta.pkgConfigModules );
            modulesConcated = concatStringsSep " " modules;
        in
        optionalString ( modules != [] ) /* bash */ ''
            declare -a library_paths=()
            declare -a cpaths=()

            IFS=" "

            for f in $( pkg-config --libs-only-L ${modulesConcated} )
            do
                # remove "-L"
                library_paths+=( "''${f#'-L'}" )
            done

            for f in $( pkg-config --cflags-only-I ${modulesConcated} )
            do
                # remove "-I"
                cpaths+=( "''${f#'-I'}" )
            done

            export CPATH=$( IFS=":"; echo "''${cpaths[*]}" )
            export LIBRARY_PATH=$( IFS=":"; echo "''${library_paths[*]}" )

            unset library_paths
            unset cpaths
        ''
    ;

}
