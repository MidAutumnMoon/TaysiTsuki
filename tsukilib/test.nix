with (builtins.getFlake (toString ../.)).lib; let pkgs = import <nixpkgs> {}; in

listAllModules ../nixos
