{

    boot = {
        loader.grub.enable = true;
        # The VNC console is fleaky, the default 5s is too short to catch
        loader.timeout = 15;
    };

    boot.kernelParams = [
        "possible_cpus=0"
    ];

}
