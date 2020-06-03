{stdenv, fetchFromGitHub, bash}:
stdenv.mkDerivation {
  name = "rbenv";
  
  # fetchFromGitHub is a build support function that fetches a GitHub
  # repository and extracts into a directory; so we can use it
  # fetchFromGithub is actually a derivation itself :)
  src = fetchFromGitHub {
    owner = "rbenv";
    repo = "rbenv";
    rev = "v1.1.2";
    sha256 = "12i050vs35iiblxga43zrj7xwbaisv3mq55y9ikagkr8pj1vmq53";
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
  	ln -s $out/libexec/rbenv $out/bin/rbenv
  '';
}