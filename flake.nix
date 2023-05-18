{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        unraid-usb-creator = pkgs.writeShellApplication {
          name = "unraid-installer";
          runtimeInputs = [
            pkgs.bash
            pkgs.coreutils
            pkgs.dosfstools
            pkgs.fzf
            pkgs.gnugrep
            pkgs.mtools
            pkgs.parted
            pkgs.unzip
            pkgs.util-linux
            pkgs.wget
          ];
          text = ''
            #!${pkgs.stdenv.shell}
            ${builtins.readFile ./unraid-installer.sh}
          '';
          checkPhase = "${pkgs.stdenv.shellDryRun} $target";
        };

      in
      {
        formatter = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
        packages.unraid-installer = unraid-usb-creator;
        packages.default = unraid-usb-creator;
      });
}
