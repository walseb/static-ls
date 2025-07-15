{

  inputs =
    {
      nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    };

  outputs = { self, nixpkgs, nixpkgs-unstable }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux.pkgs;
      pkgs-unstable = nixpkgs-unstable.legacyPackages.x86_64-linux.pkgs;
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # Liquid haskell
          z3

          zlib
          # pkgs.haskell.compiler.ghc88
          # haskell.compiler.ghc910
          # haskell.compiler.ghc98
          haskell.compiler.ghc98
          pkgs-unstable.cabal-install
          hpack

          # haskell.compiler.ghc963
          haskellPackages.fourmolu
          haskellPackages.hiedb
          sqlite
          ghcid
          cabal-install
          hpack
          alejandra
        ];
      };
    };
}
