{
  description = "bevy flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";

    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, flake-utils, naersk, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        name = "bevy";

        pkgs = (import nixpkgs) {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

        buildInputs = with pkgs; [
          wayland
          libxkbcommon
          vulkan-loader
          alsa-lib
          udev
        ];

        nativeBuildInputs = with pkgs; [
          pkg-config
        ];

        naersk' = pkgs.callPackage naersk {
          rustc = toolchain;
          cargo = toolchain;
        };
      in rec {
        packages = {
          default = packages.${name};

          ${name} = naersk'.buildPackage {
            inherit buildInputs;
            inherit nativeBuildInputs;

            src = ./.;

            meta.mainProgram = name;
          };
        };

        apps.default = {
          type = "app";

          program = let
              pkg = packages.bevy-ps1;
            in pkgs.lib.getExe (pkgs.runCommandLocal
              "${pkg.name}-wrapper"
              {
                nativeBuildInputs = [ pkgs.makeWrapper ];
                meta = { inherit (pkg.meta) mainProgram; };
              }
              ''
                makeWrapper ${pkgs.lib.getExe pkg} $out/bin/${pkg.meta.mainProgram}
                  --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath buildInputs}
              '');
        };

        devShells.default = pkgs.mkShell {
          inherit buildInputs;

          nativeBuildInputs = nativeBuildInputs ++ [ toolchain ];
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
        };
      }
    );
}
