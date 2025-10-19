{
  description = "A Nix flake for cross-compiling a static Go binary for aarch64-linux.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # -- System Configuration --
      hostSystem = "x86_64-linux";
      pkgs = import nixpkgs { system = hostSystem; };
      lib = pkgs.lib;

      # -- Target Configuration for Termux --
      targetSystem = "aarch64-multiplatform-musl";
      pkgsCross = pkgs.pkgsCross.${targetSystem};

      # -- Dependencies --
      # Get the STATIC, cross-compiled libraries for the target system
      libusbStatic = pkgsCross.pkgsStatic.libusb1.dev;
      libftdi1Static = (pkgsCross.pkgsStatic.libftdi1.overrideAttrs { doCheck = false; doInstallCheck = false; }).override { pythonSupport = false; docSupport = false; cppSupport = false; };


    in
    {
      # -- The Development Shell --
      # Run `nix develop` to enter this shell.
      devShells.${hostSystem}.default = pkgs.mkShell {
        # Tools needed on the host to perform the build
        packages = [
          pkgs.go
          pkgs.pkg-config
          pkgsCross.stdenv.cc # The C cross-compiler for aarch64-linux
        ];

        # This hook runs when you enter the shell.
        shellHook = ''
          echo "--- Nix Flake for aarch64-linux Cross-Compilation ---"

          # Point pkg-config to the cross-compiled static libraries
          export PKG_CONFIG_PATH="${libusbStatic}/lib/pkgconfig:${libftdi1Static}/lib/pkgconfig"

          export GOOS=linux
          export GOARCH=arm64
          export CGO_ENABLED=1
          export CC="${lib.getExe pkgsCross.stdenv.cc}"
          export CXX="${lib.getExe' pkgsCross.stdenv.cc "aarch64-unknown-linux-musl-g++"}"
          libusbStaticLib="${lib.getLib pkgsCross.pkgsStatic.libusb1}"
          
          export CGO_CFLAGS="-I${libusbStatic}/include/libusb-1.0 -I${libusbStatic}/include -I${libftdi1Static}/include/libftdi1 -I${libftdi1Static}/include"
          export CGO_LDFLAGS="-L${libftdi1Static}/lib -L''${libusbStaticLib}/lib ${libftdi1Static}/lib/libftdi1.a ''${libusbStaticLib}/lib/libusb-1.0.a -static"

          echo "Go target: $GOOS/$GOARCH"
          echo "pkg-config path: $PKG_CONFIG_PATH"
          echo ""
          echo "Ready to build. Run './build.sh' to create a static aarch64 binary."
          echo "---------------------------------------------------------"
        '';
      };
    };
}
