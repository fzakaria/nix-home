{ stdenv, fetchFromGitHub }:
stdenv.mkDerivation {
  name = "ruby-build";

  # fetchFromGitHub is a build support function that fetches a GitHub
  # repository and extracts into a directory; so we can use it
  # fetchFromGithub is actually a derivation itself :)
  src = fetchFromGitHub {
    owner = "rbenv";
    repo = "ruby-build";
    rev = "16421762a6a7901c1c12811940187e40f7dfc3b9";
    sha256 = "1j4bf5x6v6i95rn667m7r1bfzfqlqyh4ml526jhac5vsavz0gjl0";
  };

  buildPhase = ''
    PREFIX=$out ./install.sh
  '';
}
