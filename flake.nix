{
  description = "Flake para construir o pacote AudioRelay";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... } @ inputs: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
  in {
    packages."x86_64-linux".audio-relay = pkgs.stdenv.mkDerivation rec {
      pname = "audiorelay";
      version = "0.27.5";

      src = pkgs.fetchzip {
        url = "https://dl.audiorelay.net/setups/linux/audiorelay-0.27.5.tar.gz";
        sha256 = "sha256-KfhAimDIkwYYUbEcgrhvN5DGHg8DpAHfGkibN1Ny4II=";
        stripRoot = false;
      };

      nativeBuildInputs = [
        pkgs.makeWrapper
        pkgs.zip
      ];

      runtimeLibs = [
        pkgs.libglvnd
        pkgs.alsaLib
        pkgs.libpulseaudio
        pkgs.stdenv.cc.cc.lib
      ];

      manifest = ''
        Manifest-Version: 1.0
        Main-Class: com.azefsw.audioconnect.desktop.app.MainKt
        Specification-Title: Java Platform API Specification
        Specification-Version: 17
        Specification-Vendor: Oracle Corporation
        Implementation-Title: Java Runtime Environment
        Implementation-Version: 17.0.6
        Implementation-Vendor: Eclipse Adoptium
        Created-By: 17.0.5 (Eclipse Adoptium)
      '';

      desktopItem = pkgs.makeDesktopItem {
        name = "audiorelay";
        desktopName = "AudioRelay";
        comment = "Stream audio between your devices";
        categories = [ "AudioVideo" "Audio" "Network" ];
        icon = "audiorelay";
        exec = "audiorelay";
        startupNotify = true;
        startupWMClass = "com-azefsw-audioconnect-desktop-app-MainKt";
      };

      patchPhase = ''
        mkdir META-INF
        echo '${manifest}' > META-INF/MANIFEST.MF
        zip -r lib/app/audiorelay.jar META-INF/MANIFEST.MF
      '';

      installPhase = ''
        runHook preInstall

        install -Dm644 ${desktopItem}/share/applications/audiorelay.desktop $out/share/applications/audiorelay.desktop
        install -Dm644 lib/AudioRelay.png $out/share/pixmaps/audiorelay.png

        install -Dm644 lib/app/audiorelay.jar $out/lib/audiorelay.jar

        install -D lib/runtime/lib/libnative-rtaudio.so $out/lib/libnative-rtaudio.so
        install -D lib/runtime/lib/libnative-opus.so $out/lib/libnative-opus.so

        makeWrapper ${pkgs.temurin-bin-17}/bin/java $out/bin/audiorelay \
          --add-flags "-jar $out/lib/audiorelay.jar" \
          --prefix LD_LIBRARY_PATH : $out/lib/ \
          --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath runtimeLibs}

        runHook postInstall
      '';

      meta = {
        description = "Application to stream every sound from your PC to one or multiple Android devices";
        homepage = "https://audiorelay.net";
        downloadPage = "https://audiorelay.net/downloads";
        license = pkgs.lib.licenses.unfree;
      };
    };

    defaultPackage."x86_64-linux" = self.packages."x86_64-linux".audio-relay;
  };
}
