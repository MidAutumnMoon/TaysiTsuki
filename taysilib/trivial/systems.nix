lib:

let

    inherit ( lib )
        isString
        genAttrs
        makeExtensible
    ;

    inherit ( lib.systems )
        flakeExposed
    ;

in

{

    # mySystems :: [ string ]
    #
    # Donations are welcomed!
    mySystems = [ "x86_64-linux" ];


    # eachSystem :: (string -> 'a) -> { string = 'a }
    eachSystem = makeExtensible ( self: {
        # __systems :: [ string ]
        #
        # The list of systems triples to be generated with.
        __systems = flakeExposed;

        # appendSystems :: [ string ] -> eachSystem
        #
        # Handy method for appending extra systems
        # to the predefined system list;
        appendSystems = xs:
            assert lib.all isString xs;
            self.extend ( _: prev: { __systems = prev.__systems ++ xs; } )
        ;

        __functor = _: genAttrs self.__systems;
    } );

}
