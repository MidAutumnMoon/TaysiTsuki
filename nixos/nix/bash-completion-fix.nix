{
    writeTextFile
}:

writeTextFile {
    name = "nix-shell-completion-alias";
    destination = "/etc/bash_completion.d/nix-shell-alias";
    text = /* bash */ ''
        # `nix shell` is a shorthand alias of `nix env shell` (NixOS/nix#10807),
        # and nix only completes registered commands, so the alias is missing
        # from `nix <TAB>`. The vendor completion is sourced here because
        # registering nix ourselves suppresses bash-completion's lazy loading of it.
        if declare -F _get_comp_words_by_ref >/dev/null 2>&1; then
            . /run/current-system/sw/share/bash-completion/completions/nix 2>/dev/null || true
            complete -F _complete_nix -W 'shell' nix
        fi
    '';
}
