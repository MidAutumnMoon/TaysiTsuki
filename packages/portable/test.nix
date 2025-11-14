{
    lib,
    tsuki,
    writeText,
    hello
}:

let

    aU = writeText "tp-au.service" ''
        [Unit]

        [Service]
        Type = oneshot
        ExecStart = echo Hello

        [Install]
        WantedBy = multi-user.target
    '';

in

tsuki.portable {
    pname = "tp";
    version = "dev";

    units = [
        aU
    ];

    symlinks = [
        {src = lib.getExe hello; dst = "/hello";}
    ];

    extraPackages = [
        hello
    ];

    extraEmptyDirs = [
        "/var/lib/yeaah"
        "/yeal"
    ];
}
