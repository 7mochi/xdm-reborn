{
  description = "XDM Reborn AMXX plugin";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      i686 = pkgs.pkgsi686Linux;

      amxxpcWrapper = pkgs.writeShellScript "amxxpc-wrapper" ''
        set -eu
        dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
        exec ${i686.glibc}/lib/ld-linux.so.2 \
          --library-path "${i686.glibc}/lib:${i686.gcc.cc.lib}/lib:$dir" \
          "$dir/amxxpc.bin" "$@"
      '';

      amxxpcNixPatch = pkgs.writeShellScriptBin "amxxpc-nix-patch" ''
        set -eu

        compiler_dir="''${1:-.compiler}"
        binary="$compiler_dir/amxxpc"
        original="$compiler_dir/amxxpc.bin"

        if [ ! -f "$binary" ]; then
          echo "amxxpc not found at $binary" >&2
          exit 1
        fi

        case "$(head -c 2 "$binary")" in
          '#!') ;;
          *) mv -f "$binary" "$original" ;;
        esac

        if [ ! -f "$original" ]; then
          echo "amxxpc.bin not found at $original" >&2
          exit 1
        fi

        cp "${amxxpcWrapper}" "$binary"
        chmod +x "$binary"
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
