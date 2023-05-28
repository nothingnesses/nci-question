{
  description = "Hello";
  inputs = {
    cargo-generate = {
      url = "path:cargo-generate";
      inputs.devenv.follows = "devenv";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nci.follows = "nci";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv = {
      inputs.flake-compat.follows = "flake-compat";
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/devenv";
    };
    flake-compat = {
      flake = false;
      url = "github:edolstra/flake-compat";
    };
    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs";
      url = "github:hercules-ci/flake-parts";
    };
    nci = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:yusdacra/nix-cargo-integration";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = builtins.map (item: inputs.${item}.flakeModule) ["devenv" "nci"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        crate_name = "hello";
        crate_outputs = config.nci.outputs.${crate_name};
        override.overrideAttrs = old: {buildInputs = (old.buildInputs or []) ++ pkgs.lib.attrsets.attrVals ["openssl" "pkg-config"] pkgs;};
      in {
        devenv.shells.default = {
          languages.rust.enable = true;
          packages = [config.packages.default inputs.cargo-generate.packages.${pkgs.system}.default];
        };
        nci.projects.${crate_name}.relPath = "";
        nci.crates.${crate_name} = {
          depsOverrides = {inherit override;};
          export = true;
          overrides = {inherit override;};
          profiles.release.runTests = false;
          runtimeLibs = pkgs.lib.attrsets.attrVals ["openssl"] pkgs;
        };
        packages.default = crate_outputs.packages.release;
      };
      systems = ["x86_64-linux" "aarch64-darwin"];
    };
}
