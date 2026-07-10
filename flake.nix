{
  description = "Echo: A minimalist Spotify listener";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        name = "echo-dev";
        
        # This provides the Swift compiler and the official formatter
        packages = [
          pkgs.swift
          pkgs.swift-format
        ];

        shellHook = ''
          echo "Echo development environment loaded."
          echo "Format code with: swift-format format -i src/main.swift"
        '';
      };
    };
}
