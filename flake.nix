{
  description = "A pack of GRUB2 themes for each Linux distribution";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    { nixpkgs, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
      ];

      perSystem =
        {
          lib,
          pkgs,
          system,
          ...
        }:
        let
          inherit (lib) splitString removeSuffix mapAttrs';
          inherit (pkgs) callPackage mkShell;

          mkThemePackage = theme: callPackage ./build/default.nix { inherit theme; };

          themes = mapAttrs' (fileName: _: rec {
            name = ''${builtins.head (splitString "." fileName)}-grub-theme'';
            value = mkThemePackage (removeSuffix "-grub-theme" name);
          }) (builtins.readDir ./assets/backgrounds);
        in
        {
          _module.args.pkgs = nixpkgs.legacyPackages.${system};

          packages = {
            default = mkThemePackage "nixos";
          } // themes;

          checks = themes;

          devShells = {
            default = mkShell {
              name = "distro-grub-themes";
              nativeBuildInputs = with pkgs; [
                nixd
                nixpkgs-fmt
                act
                jq
              ];
            };
          };
        };

      flake = {
        nixosModules = {
          default = ./build/module.nix;
        };
      };
    };
}
