with (builtins.getFlake (toString ../.)).lib; let pkgs = import <nixpkgs> {}; in

{

a =
    ( brewNixpkgs <nixpkgs> {} )
;
}
