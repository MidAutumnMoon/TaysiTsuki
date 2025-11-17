{ ... }:

{

    networking = {
        useNetworkd = true;
        nftables.enable = true;
    };

    networking.firewall = {
        enable = true;
        logRefusedConnections = false;
    };


    boot.kernel.sysctl = {
        "net.core.default_qdisc" = "fq_pie";
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.ipv4.tcp_notsent_lowat" = 16384;
        "net.ipv4.tcp_slow_start_after_idle" = 0;
        "net.ipv4.tcp_no_metrics_save" = 0;
        "net.ipv4.tcp_mtu_probing" = 1;
        "net.ipv4.tcp_frto" = 0;
    };

}
