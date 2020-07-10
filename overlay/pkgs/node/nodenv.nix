{ stdenv, fetchFromGitHub, bash }:
stdenv.mkDerivation {
  name = "nodenv";

  # fetchFromGitHub is a build support function that fetches a GitHub
  # repository and extracts into a directory; so we can use it
  # fetchFromGithub is actually a derivation itself :)
  src = fetchFromGitHub {
    owner = "nodenv";
    repo = "nodenv";
    rev = "v1.3.2";
    sha256 = "0zimrxspdwjx6b65bgkc9p9jyii6mxmc5r4ww3ghmxgba38rzfh6";
  };

  buildPhase = ''
    ${bash}/bin/bash src/configure
    make -C src
  '';

  # This overrides the shell code that is run during the installPhase.
  # By default; this runs `make install`.
  # The install phase will fail if there is no makefile; so it is the
  # best choice to replace with our custom code.
  installPhase = ''
    mkdir -p $out/bin
    mv libexec $out
    mv completions $out
    ln -s $out/libexec/nodenv $out/bin/nodenv
  '';
}
