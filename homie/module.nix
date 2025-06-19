{ pkgs, ... }:

{

    _module.args = rec {
        tsukiObservatory = "{{ home }}/TaysiTsuki";

        # convinient function to get a file from dotfile dir
        dots = {
            __toString = self: "${tsukiObservatory}/homie";
            get = path: "${toString dots}/${path}";
        };
    };

    packages = with pkgs; [
        sops
        tsuki.inori
        tsuki.opentofu
    ];

}
