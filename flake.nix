{
  description = "Cloud id generator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;

        craneLib = crane.lib.${system};
        pythonFilter = path: _type: builtins.match ".*py$" path != null;
        pythonOrCargo = path: type:
          (pythonFilter path type) || (craneLib.filterCargoSources path type);

        cloud-id-generator = craneLib.buildPackage {
          src = lib.cleanSourceWith {
            src = craneLib.path ./.;
            filter = pythonOrCargo;
          };

          strictDeps = true;

          nativeBuildInputs = [
            pkgs.pkg-config
          ];
          buildInputs = with pkgs; [
            # Add additional build inputs here
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # Additional darwin specific inputs can be set here
            pkgs.libiconv
          ];

          # Additional environment variables can be set directly
        };

        dockerImage = pkgs.dockerTools.buildImage {
          name = "cloud-id-generator";
          tag = "latest";
          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = with pkgs; [
              cloud-id-generator
            ];
            pathsToLink = [ "/bin" ];
          };
          config = {
            Cmd = [ "${cloud-id-generator}/bin/cloud-id-generator" ];
          };
        };
      in
      with pkgs;
      {
        checks = {
          inherit cloud-id-generator;
        };

        packages = {
          inherit cloud-id-generator dockerImage;
          default = cloud-id-generator;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = cloud-id-generator;
        };

        devShells.default = craneLib.devShell {
          # Inherit inputs from checks.
          checks = self.checks.${system};

          # Extra inputs can be added here; cargo and rustc are provided by default.
          packages = [
            rust-analyzer
            git
            go-task
            sops
            age
            dive
            pkg-config
          ];
        };
      });
}




