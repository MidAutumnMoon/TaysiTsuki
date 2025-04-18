{ lib, pkgs, ... }:

{

    programs.fish.init = /* fish */ ''
        # See https://asciinema.org/a/661290
        #
        # \e[0;0H : move cursor to 0,0 to reset its position
        # \e[$LINES;0H : move cursor $LINES down
        echo -ne "\e[0;0H\e[$LINES;0H"

        # Bind Ctrl+L
        bind --user \cl '
            echo -n ( clear | string replace \\e\\[3J "" ) ;
            commandline -f repaint ;
            echo -ne "\e[0;0H\e[$LINES;0H" ;
        '
    '';

    programs.fish.interactiveInit = /*fish*/ ''
        ${builtins.readFile ./fish/tide.fish}
        ${builtins.readFile ./fish/git-abbr.fish}

        # Tell Windows Terminal to open new tabs with the same CWD
        function __windows_terminal --on-variable PWD
            set -q WT_SESSION
            and printf "\e]9;9;%s\e\\" ( wslpath -w "$PWD" )
        end
    '';

    environment.shellAliases = {
        "-" = "cd -";
        "ldd" = "libtree";
        "sys" = "systemctl";
        "ca" = "cargo";
        "g" = "git";
        "n" = "nix";
        ".ns" = "nh os switch";
        ".nt" = "nh os test";
        ".nb" = "nh os build";
        ".npl" = "nh os repl";
    };

    programs.fish.functions = {

        "colmena".body = /* fish */
            "command colmena --experimental-flake-eval $argv";

        "git".body = /* fish */ ''
            # if git is invoked with no arguments,
            # jump to the repo's root dir
            if test ( count $argv ) -eq 0
                cd -- "$( command git rev-parse --show-toplevel )"
                return $status
            end
            command git $argv
        '';

        "ip".body = /*fish*/ "command ip --color=auto $argv";

        "ls".body = /*fish*/ ''
            command "${lib.getExe pkgs.eza}" \
                "--group-directories-first" \
                "--color=auto" \
                "--sort=name" \
                "--smart-group" \
                $argv
        '';

        "nix".body = /*fish*/ ''
            set -f toplevel "$( command git rev-parse --show-toplevel )"

            # Check whether the repo has flake.
            if command nix flake metadata &> /dev/null
                # if the workspace has flake and git status is dirty
                if [ -n "$( git status --porcelain 2> /dev/null )" ]
                    command git add --all --intent-to-add
                end
            end

            command nix $argv
        '';

    };

    programs.fish.functions."ytdl".body = /*fish*/ ''
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

}
