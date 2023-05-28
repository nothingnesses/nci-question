{
  description = "cargo, make me a project";
  inputs = {
    cargo-generate = {
      flake = false;
      url = "github:cargo-generate/cargo-generate";
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
    nix-filter.url = "github:numtide/nix-filter";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };
  outputs = inputs: let
      name = "cargo-generate";
    in inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      debug = true;
      imports = builtins.map (item: inputs.${item}.flakeModule) ["devenv" "nci"];
      nci.source = (import inputs.nix-filter) {
        root = inputs.${name};
        include = ["Cargo.lock" "Cargo.toml" "README.md" "src"];
      };
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        crate_outputs = config.nci.outputs.${name};
        override.overrideAttrs = old: {buildInputs = (old.buildInputs or []) ++ pkgs.lib.attrsets.attrVals ["libgit2" "openssl" "perl" "pkg-config"] pkgs;};
      in {
        devenv.shells.default = {
          languages.rust.enable = true;
          packages = [config.packages.default];
        };
        nci.projects.${name}.relPath = "";
        nci.crates.${name} = {
          depsOverrides = {inherit override;};
          export = true;
          overrides = {inherit override;};
          profiles.release = {
            features = [];
            runTests = false;
          };
          runtimeLibs = pkgs.lib.attrsets.attrVals ["libgit2" "openssl"] pkgs;
        };
        packages.default = crate_outputs.packages.release;
      };
      systems = ["x86_64-linux" "aarch64-darwin"];
    };
}
