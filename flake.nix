{
  description = "This is an 'nix flake' :)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    attrs@{ self
    , nixpkgs
    , flake-utils
    ,
    }:
    let
      name = "video-to-reels";

      suportedSystems = [
        "aarch64-darwin"
        # "aarch64-linux"
        # "x86_64-darwin"
        "x86_64-linux"
      ];

    in
      flake-utils.lib.eachSystem suportedSystems (suportedSystem:
        let
          pkgsAllowUnfree = import nixpkgs { system = suportedSystem; config = { allowUnfree = true; }; };

          # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues attrs));
        in {

          devShells.default = pkgsAllowUnfree.mkShell {
            buildInputs = with pkgsAllowUnfree; [
              bashInteractive
              coreutils
              ffmpeg-full
              imagemagick
              nodejs
              yt-dlp
              zx

              pleaseKeepMyInputs
            ];

            shellHook = ''

              test -d .profiles || mkdir -v .profiles

              test -L .profiles/dev \
              || nix develop .# --profile .profiles/dev --command sh 'echo'

              test -L .profiles/dev-shell-default \
              || nix build $(nix eval --impure --raw .#devShells.x86_64-linux.default.drvPath) --out-link .profiles/dev-shell-default

              echo -e 'video' | "${pkgsAllowUnfree.figlet}/bin/figlet" | cat
              echo -e '       to' | "${pkgsAllowUnfree.figlet}/bin/figlet" | cat
              echo -e 'reels' | "${pkgsAllowUnfree.figlet}/bin/figlet" | cat

              cd detect-face
              test -d node_modules || npm install
              cd ..

              test -f origins/bard-replit.mp4 || (cd origins && yt-dlp --ignore-config -o bard-replit.mp4 -f mp4 XBGS6FnLwa4 && cd ..)
              zx convert.mjs -i origins/bard-replit.mp4
            '';
          };
        }
    );
}
