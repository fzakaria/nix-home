{stdenv, fetchFromGitHub}:
stdenv.mkDerivation {
  name = "ruby-build";
  
  # fetchFromGitHub is a build support function that fetches a GitHub
  # repository and extracts into a directory; so we can use it
  # fetchFromGithub is actually a derivation itself :)
  src = fetchFromGitHub {
    owner = "rbenv";
    repo = "ruby-build";
    rev = "v20200520";
    sha256 = "1z24hid1jrbvqf5f42lw7rgs533jcmcj5xjrsvrnm2l9amh13d5j";
  };

  buildPhase = ''
  	PREFIX=$out ./install.sh
  '';
}
