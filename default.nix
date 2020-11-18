let
  pkgs = import <nixpkgs> {};
  nix-pre-commit-hooks = import (builtins.fetchTarball "https://github.com/cachix/pre-commit-hooks.nix/tarball/master");
  gitignoreSrc = pkgs.fetchFromGitHub { 
    owner = "hercules-ci";
    repo = "gitignore";
    rev = "c4662e6";
    sha256 = "sha256:1npnx0h6bd0d7ql93ka7azhj40zgjp815fw2r6smg8ch9p7mzdlx";
  };
  inherit (import gitignoreSrc { inherit (pkgs) lib; }) gitignoreSource;
in {
  pre-commit-check = nix-pre-commit-hooks.run {
    src = gitignoreSource ./.;
    hooks = {
      elm-format.enable = true;
      ormolu.enable = true;
      hlint.enable = true;
    };
  };
}
