{
  description = "cargo, make me a project";
  inputs = {
    cargo-generate = {
      flake = false;
      url = "github:cargo-generate/cargo-generate";
    };
    nci = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:yusdacra/nix-cargo-integration";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = inputs: let
    name = "cargo-generate";
    pkgs = common: packages: builtins.map (element: common.pkgs.${element}) packages;
  in
    inputs.nci.lib.makeOutputs {
      config = common: {
        outputs = {
          defaults = {
            app = name;
            package = name;
          };
        };
        runtimeLibs = pkgs common ["openssl"];
      };
      pkgConfig = common: let
        override.overrideAttrs = old: {buildInputs = (old.buildInputs or []) ++ pkgs common ["openssl" "perl" "pkg-config"];};
      in {
        ${name} = {
          app = true;
          build = true;
          depsOverrides = {inherit override;};
          overrides = {inherit override;};
          profiles = {release = false;};
        };
      };
      root = inputs.${name};
    };
}
