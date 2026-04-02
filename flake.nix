{
  description = "StardustXR based OpenXR Overlay";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    server = {
      url = "github:StardustXR/server";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flatland.follows = "flatland";
    };
    flatland = {
      url = "github:StardustXR/flatland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    protostar = {
      url = "github:StardustXR/protostar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gravity = {
      url = "github:StardustXR/gravity";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    black_hole = {
      url = "github:StardustXR/black-hole";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    solar_sailer = {
      url = "github:StardustXR/solar-sailer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    non_spatial_input = {
      url = "github:StardustXR/non-spatial-input";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [];
      systems = [ "aarch64-linux" "x86_64-linux" "riscv64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
      {
        # edit these to add/remove clients
        packages.startup_script = pkgs.writeShellApplication {
          name = "startup_script";
          runtimeInputs = [
            inputs'.flatland.packages.default
            inputs'.protostar.packages.default
            inputs'.gravity.packages.default
            inputs'.black_hole.packages.default
            inputs'.solar_sailer.packages.default
            inputs'.non_spatial_input.packages.default
            pkgs.xwayland-satellite
          ];
          ## and this is the startup script
          text = ''
            unset LD_LIBRARY_PATH
            if [[ -v LD_LIBRARY_PATH_ORIGINAL ]]; then
              echo "Restored pre-exisiting LD_LIBRARY_PATH"
              export LD_LIBRARY_PATH="$LD_LIBRARY_PATH_ORIGINAL"
            fi

            xwayland-satellite :10 &
            export DISPLAY=:10

            flatland &
            gravity -- 0 0.0 -0.5 hexagon_launcher &
            gravity -- 0 0.1 -0.5 solar-sailer &
            black-hole &

            WAYLAND_DISPLAY=$FLAT_WAYLAND_DISPLAY manifold | simular &
          '';
        };
        packages.flatscreen = pkgs.writeShellApplication {
          name = "flatscreen";
          runtimeInputs = [ self'.packages.telescope ];
          text = ''telescope -f'';
        };
        packages.telescope = pkgs.writeShellApplication {
          name = "telescope";
          runtimeInputs = [
            inputs'.server.packages.default
          ];
          text = ''
          	stardust-xr-server -d -o 6 -e "${self'.packages.startup_script}/bin/startup_script" "$@"
          '';
        };
        packages.default = self'.packages.telescope;

        apps.flatscreen = {
          type = "app";
          program = "${self'.packages.flatscreen}/bin/flatscreen";
        };
        apps.telescope = {
          type = "app";
          program = "${self'.packages.telescope}/bin/telescope";
        };
        apps.default = self'.apps.telescope;
      };
      flake = {};
    };
}
