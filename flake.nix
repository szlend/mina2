{
  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };
    flake-utils = { url = "github:numtide/flake-utils"; };
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
  };

  outputs =
    { self, nixpkgs, flake-utils, ... }:

    flake-utils.lib.eachDefaultSystem (system:
      with nixpkgs.legacyPackages.${system}.pkgs; rec {
        devShell = pkgs.mkShell {
          COMPOSE_FILE = "docker-compose.base.yml:docker-compose.dev.yml";

          buildInputs = with pkgs; [
            (beam.packagesWith erlangR23).elixir_1_11
            nodejs-12_x
          ];
        };
      }
    );
}
