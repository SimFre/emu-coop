# Run with `nix-shell shell.nix`

# { config, lib, pkgs ? import <nixpkgs-unstable> {}, ... }:

let
  pkgs = import <nixpkgs> { };
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    opencode
    lua
    #snes9x
    #snes9x-gtk
  ];

}
