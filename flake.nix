{
  description = ''
    Mainly a PHP Language Server with more features than you can shake a stick
        at.'';

  inputs = {
    nixpkgs.url =
      "github:nixos/nixpkgs/6e3a86f2f73a466656a401302d3ece26fba401d9";
    flake-utils.url = "github:numtide/flake-utils";

    phpactor = {
      url = "github:phpactor/phpactor/2022.11.12";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, phpactor }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        src = phpactor;

        version = "2022.11.12";
        vendor = pkgs.stdenvNoCC.mkDerivation {
          pname = "phpactor-vendor";
          inherit src version;

          # See https://github.com/NixOS/nix/issues/6660
          dontPatchShebangs = true;

          nativeBuildInputs = [ pkgs.php pkgs.phpPackages.composer ];

          buildPhase = ''
            runHook preBuild

            substituteInPlace composer.json \
              --replace '"config": {' '"config": { "autoloader-suffix": "Phpactor",' \
              --replace '"name": "phpactor/phpactor",' '"name": "phpactor/phpactor", "version": "${version}",'
            composer install --no-interaction --optimize-autoloader --no-dev --no-scripts

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out
            cp -ar ./vendor $out/

            runHook postInstall
          '';

          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = "sha256-o7Bsap5EetILQrJaz2uysXBZueOBO8ywopNXBqxAROc=";
        };

      in rec {
        packages.default = pkgs.stdenvNoCC.mkDerivation {
          pname = "phpactor";
          inherit src version;

          buildInputs = [ pkgs.php ];

          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/share/php/phpactor $out/bin
            cp -r . $out/share/php/phpactor
            cp -r ${vendor}/vendor $out/share/php/phpactor
            ln -s $out/share/php/phpactor/bin/phpactor $out/bin/phpactor

            runHook postInstall
          '';

          meta = {
            description = "Mainly a PHP Language Server";
            homepage = "https://github.com/phpactor/phpactor";
            license = pkgs.lib.licenses.mit;
          };
        };
      });
}
