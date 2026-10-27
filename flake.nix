{
  description = "XDM Reborn AMXX plugin";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      i686 = pkgs.pkgsi686Linux;

      amxxpcNixPatch = pkgs.writeShellScriptBin "amxxpc-nix-patch" ''
        set -eu

        compiler_dir="''${1:-.compiler}"
        binary="$compiler_dir/amxxpc"

        if [ ! -f "$binary" ]; then
          echo "amxxpc not found at $binary" >&2
          exit 1
        fi

        rpath="${i686.glibc}/lib:\$ORIGIN"

        ${pkgs.patchelf}/bin/patchelf \
          --set-interpreter "${i686.glibc}/lib/ld-linux.so.2" \
          --set-rpath "$rpath" \
          "$binary"

        for lib in "$compiler_dir"/amxxpc32.so; do
          [ -f "$lib" ] || continue
          ${pkgs.patchelf}/bin/patchelf --set-rpath "$rpath" "$lib"
        done
      '';
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nodejs_24
          just
          amxxpcNixPatch
        ];

        shellHook = ''
          if [ -f .compiler/amxxpc ]; then
            amxxpc-nix-patch .compiler >/dev/null 2>&1 || true
          fi

          echo "XDM Reborn"
          echo "  just install"
          echo "  just build"
          echo "  just watch"
        '';
      };
    };
}
