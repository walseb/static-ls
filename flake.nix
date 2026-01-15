{
  inputs =
    {
      nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    };

  outputs = { self, nixpkgs, nixpkgs-unstable }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux.pkgs;
      pkgs-unstable = nixpkgs-unstable.legacyPackages.x86_64-linux.pkgs;

      raylibRev = "2a0963ce0936abe0cd3ec32882638d860e435d16";
      raylibHash = "sha256-4p3nq04irS8AFojH88Bh1r8KiOjQhZf7nFmQhf1EDU8=";

      raylib = pkgs.raylib.overrideAttrs (old: {
        patches = [];
        version = "5.0.0";
        src = pkgs.fetchFromGitHub {
          owner = "raysan5";
          repo = "raylib";
          rev = raylibRev;
          sha256 = raylibHash;
        };
        postFixup = "cp ../src/*.h $out/include/";
      });

      # https://github.com/Anut-py/h-raylib/blob/master/flake.nix
      rayguiRev = "1e03efca48c50c5ea4b4a053d5bf04bad58d3e43";
      rayguiHash = "sha256-PzQZxCz63EPd7sVFBYY0T1s9jA5kOAxF9K4ojRoIMz4=";
      raygui = pkgs.stdenv.mkDerivation { # A bit of a hack to get raygui working
        name = "raygui";
        version = "4.1.0";
        src = pkgs.fetchFromGitHub {
          owner = "raysan5";
          repo = "raygui";
          rev = rayguiRev;
          sha256 = rayguiHash;
        };
        nativeBuildInputs = [];
        postFixup = "mkdir -p $out/include/ && cp ./src/raygui.h $out/include/ && cp ./styles/**/*.h $out/include/";
      };

      native-build-libs = with pkgs; [
        # https://discourse.nixos.org/t/pkg-config-cant-find-gobject/38519/3
        pkg-config
        (import /home/admin/root/dep/nixos/modules/softfloat-3.nix {inherit stdenv; inherit pkgs;})
      ];

      build-libs = with pkgs; [
        hpack

        # Liquid haskell
        z3

        zlib
        # pkgs.haskell.compiler.ghc88
        haskell.compiler.ghc910
        # haskell.packages.ghc910.cabal-install
        # haskell.compiler.ghc98
        # haskell.compiler.ghc9121

        pkgs-unstable.cabal-install

      ];

      # Many are excluded from here. Building runtime libms from the system version of nix is superior.
      runtimeLibs = with pkgs; [
        msmtp

        SDL2
        xorg.libXext
        libGLU
        libGL
        xorg.libX11
        xorg.libXi
        xorg.libXrandr
        xorg.libXxf86vm
        xorg.libXcursor
        xorg.libXinerama
        xorg.libXau
        xorg.libXdmcp
        xorg.libxcb
        libffi # Is this needed? Taken from here: https://github.com/alt-romes/ghengin/blob/master/nix/vulkan-validation-layers-overlay.nix

        # https://github.com/NixOS/nixpkgs/issues/197407
        raylib
        raygui
        xorg.xinput
        glfw
        # vulkan-extension-layer
        vulkan-headers
        vulkan-loader
        vulkan-tools
        vulkan-tools-lunarg
        vulkan-validation-layers
        vulkan-utility-libraries

        spirv-headers
        spirv-tools


        zlib
        glslang
        shaderc
        mangohud

        freetype

        haskellPackages.threadscope

        # debugging
        gdb
        libelf
        libdwarf
        elfutils   

        # llvm

      ];
      all-libs = runtimeLibs ++ build-libs;
      # all-library-path = "${pkgs.lib.makeLibraryPath all-libs}";
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        nativeBuildInputs = native-build-libs;
        buildInputs = all-libs;

        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath all-libs;

        # Not really used, I think. But here are the headers.
        VULKAN_SDK = "${pkgs.vulkan-headers}";

        # Validation layers
        VK_LAYER_PATH = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";

        # Not needed
        #   export PKG_CONFIG_PATH=${pkgs.SDL2}/lib/pkgconfig
        #   export C_INCLUDE_PATH=${pkgs.SDL2.dev}/include
        #   export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${all-library-path}"
        #   export LIBRARY_PATH="${all-library-path}"
        shellHook = ''
          export MANGOHUD=1
          # export VK_LOADER_DEBUG="all"
          # export LIBGL_ALWAYS_SOFTWARE=1
          # export MESA_VK_DEVICE_SELECT=10005:0
        '';
      };

      # Build option for email not needed currently
      # devShells.x86_64-linux.buildEmailScheduler = pkgs.mkShell {
      #   buildInputs = build-libs;
      # };
    };
}
