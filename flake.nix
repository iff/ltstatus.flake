{
  description = "flake for ltstatus";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix.url = "github:DavHau/mach-nix";

    ltstatus = {
      url = "github:dkuettel/ltstatus";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ltstatus, flake-utils, mach-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        machNix = import mach-nix {
          inherit pkgs;
          python = "python39";
        };

        ltstatusPythonDependencies = machNix.mkPython {
          # TODO: requirements = builtins.readFile ./python/requirements.txt;

          requirements = ''
            jeepney ~= 0.8.0
            nvidia-ml-py ~= 11.515.48
            psutil ~= 5.9.0
          '';

          providers = {
            _default = "wheel";
          };
        };

        ltstatuspkg = pkgs.stdenv.mkDerivation {
          name = "ltstatus";
          version = "latest";
          src = ltstatus;

          buildInputs = [ ltstatusPythonDependencies pkgs.makeWrapper ];

          installPhase = ''
            mkdir $out
            cp -r * $out/

            # patch bin/ltstatus to use our Python
            echo "PYTHONPATH=$out/python python3.9 \$@" > $out/bin/ltstatus
            wrapProgram $out/bin/ltstatus --prefix PATH : ${ltstatusPythonDependencies}/bin \
          '';
        };

      in
      {
        packages = {
          default = ltstatuspkg;
          ltstatus = ltstatuspkg;
        };
      }
    );
}
