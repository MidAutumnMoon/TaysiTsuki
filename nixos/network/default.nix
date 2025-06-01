{ lib, ... }:

{

    networking = {
        useNetworkd = true;
    };

    services.resolved = {
        enable = lib.mkDefault true;
        extraConfig = ''
            Cache = no-negative
        '';
    };

    boot.kernel.sysctl = {
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.ipv4.tcp_notsent_lowat" = 16384;
        "net.ipv4.tcp_slow_start_after_idle" = 0;
        "net.ipv4.tcp_no_metrics_save" = 0;
        "net.core.rmem_max" = 67108864;
        "net.core.wmem_max" = 67108864;
        "net.ipv4.tcp_mtu_probing" = 1;
        "net.core.somaxconn" = 16384;
        # calculated based on 8G ram
        "net.ipv4.tcp_mem" = "471025 942050 1413075";
        "net.ipv4.udp_mem" = "471025 942050 1413075";
    };

}
