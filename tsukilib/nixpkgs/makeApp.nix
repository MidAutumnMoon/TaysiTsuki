lib:

let

    inherit ( lib )
        isDerivation
    ;

in

{

    # makeApp :: drv -> app
    #
    # Create an "app" from derivation;
    #
    makeApp = drv:
        assert isDerivation drv;
        {
            type = "app";
            program = lib.getExe drv;
        };

}
