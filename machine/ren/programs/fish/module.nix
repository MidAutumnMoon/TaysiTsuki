{ pkgs, lib, ... }:

{

    programs.fish.enable = true;

    environment.shellAliases = {
        "ldd" = "libtree";
        "sys" = "systemctl";
        "ca" = "cargo";
        "n" = "nix";
        "j" = "jj";
        ".ns" = "nh switch";
        ".nt" = "nh test";
        ".nb" = "nh boot";
        ".nbd" = "nh build";
    };

    programs.fish.init = /* fish */ ''
        # See https://asciinema.org/a/661290
        #
        # \e[0;0H : move cursor to 0,0 to reset its position
        # \e[$LINES;0H : move cursor $LINES down
        echo -ne "\e[0;0H\e[$LINES;0H"
        bind --user ctrl-l '
            echo -n ( clear | string replace \\e\\[3J "" ) ;
            commandline -f repaint ;
            echo -ne "\e[0;0H\e[$LINES;0H" ;
        '
    '';

    programs.fish.interactiveInit = /*fish*/ ''
    '';

    programs.fish.functions = {

        "ip".body = /*fish*/ "command ip --color=auto $argv";

        "ytdl".body = /*fish*/ ''
            command "${lib.getExe pkgs.yt-dlp}" \
            --no-playlist \
            -S "quality:res,hdr,codec:av1" \
            -f "bestvideo[height<=1080]+bestaudio/best" \
            --add-metadata \
            --embed-chapters \
            --embed-thumbnail \
            --embed-metadata \
            --embed-subs \
            --sub-langs 'all' \
            --ppa "EmbedSubtitle:-default_mode infer_no_subs" \
            --compat-options "no-live-chat" \
            --mtime \
            --output '%(fulltitle)s.%(ext)s' \
            --merge-output-format "mkv" \
            -- "$argv[1]"
        '';
    };

}
