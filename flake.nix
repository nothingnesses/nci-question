{
  description = "Hello";
  inputs = {
    cargo-generate = {
      url = "path:cargo-generate";
      inputs.nci.follows = "nci";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nci = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:yusdacra/nix-cargo-integration";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = inputs: let
    name = "hello";
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
        shell = {
          packages = builtins.map (element: {package = inputs.${element};}) ["cargo-generate"];
        };
      };
      pkgConfig = common: let
        override.overrideAttrs = old: {buildInputs = (old.buildInputs or []) ++ pkgs common ["openssl" "pkg-config"];};
      in {
        ${name} = {
          app = true;
          build = true;
          depsOverrides = {inherit override;};
          overrides = {inherit override;};
          profiles = {release = false;};
        };
      };
      root = ./.;
    };
}
