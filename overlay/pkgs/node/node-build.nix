{ stdenv, fetchFromGitHub }:
stdenv.mkDerivation {
  name = "node-build";

  # fetchFromGitHub is a build support function that fetches a GitHub
  # repository and extracts into a directory; so we can use it
  # fetchFromGithub is actually a derivation itself :)
  src = fetchFromGitHub {
    owner = "nodenv";
    repo = "node-build";
    rev = "v4.9.0";
    sha256 = "0i6rvkdw4wi3275d2knsnaqqm1y6368amjbjgib213rqxjisa9ws";
  };

  buildPhase = ''
    PREFIX=$out ./install.sh
  '';
}
