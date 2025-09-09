{
  description = "TPopeyPad";

  inputs = {
    # we use nixos-unstable to benefit from the cache + it has less breakage
    # than nixpkgs-unstable/master
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ]
      (system:
        let
          lib = nixpkgs.legacyPackages.${system}.lib;
          pkgs = import nixpkgs {
            inherit system;
          };

          jkNode = pkgs.nodejs_24;
          pnpm = (pkgs.pnpm).override({ nodejs = jkNode; });

        in

        {

        devShells = {
          default = pkgs.mkShell {
            name = "popeypad";
            buildInputs = [
              jkNode
              pkgs.just
              pkgs.docker-compose
              # pnpm has to be installed manually because of https://github.com/NixOS/nixpkgs/issues/145432
              pnpm
              pkgs.awscli
              pkgs.podman
              pkgs.bashInteractive
            ];

            shellHook = ''
              echo "Welcome to the PopeyPad development shell!"
            '';
          };
        };
      });
}
