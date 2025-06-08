lib:

let

    inherit ( lib )
        isAttrs
        filterAttrs
    ;

in {

    # rejectUnset :: attrset -> attrset
    #
    # Filter out errors
    rejectUnset = input:
        assert isAttrs input;
        filterAttrs ( n: v: builtins.tryEval v |> ( it: it.success ) ) input;

}
