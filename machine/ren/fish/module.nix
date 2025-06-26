{ pkgs, lib, ... }:

{

    environment.shellAliases = {
        "ldd" = "libtree";
        "sys" = "systemctl";
        "ca" = "cargo";
        "g" = "git";
        "n" = "nix";
        ".ns" = "nh os switch";
        ".nt" = "nh os test";
        ".nb" = "nh os boot";
        ".nbd" = "nh os build";
        ".npl" = "nh os repl";
        "cm" = "colmena";
    };

    programs.fish.init = /* fish */ ''
        # See https://asciinema.org/a/661290
        #
        # \e[0;0H : move cursor to 0,0 to reset its position
        # \e[$LINES;0H : move cursor $LINES down
        echo -ne "\e[0;0H\e[$LINES;0H"
        bind --user \cl '
            echo -n ( clear | string replace \\e\\[3J "" ) ;
            commandline -f repaint ;
            echo -ne "\e[0;0H\e[$LINES;0H" ;
        '
    '';

    programs.fish.interactiveInit = /*fish*/ ''
        ${builtins.readFile ./git-abbr.fish}
        atuin init fish | source
    '';

    programs.fish.functions = {

        "git".body = /* fish */ ''
            # if git is invoked with no arguments,
            # jump to the repo's root dir
            if test ( count $argv ) -eq 0
                set -f top ( command git rev-parse --show-toplevel 2> /dev/null )
                test $status = 0
                and cd -- "$top"
                and return
            end
            command git $argv
        '';

        "ip".body = /*fish*/ "command ip --color=auto $argv";

        "nix".body = /*fish*/ ''
            # Check whether the repo has flake.
            if command nix flake metadata &> /dev/null
                # if the workspace has flake and git status is dirty
                if [ -n "$( git status --porcelain 2> /dev/null )" ]
                    command git add --all --intent-to-add
                end
            end
            command nix $argv
        '';

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
