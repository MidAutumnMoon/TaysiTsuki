{
    makeSetupHook,
}:

{

    # Prefix binaries in "$out/bin" with a comma,
    # making the command looks like ",cmd".
    prefixCommaToBin =
        makeSetupHook {
            name = "prefix-comma-to-bin";
        } ./prefix-comma-to-bin.sh;

}
