lib:

let

    inherit ( lib )
        isList
    ;

in

{

    # appendElem :: a -> [any] -> [any, a]
    #
    # Append an element to a list.
    appendElem = elem: list:
        assert isList list;
        list ++ [ elem ];

}
