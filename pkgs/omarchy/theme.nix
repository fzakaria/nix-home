# Renders one Omarchy theme at build time into the tree Omarchy expects at
# ~/.local/state/omarchy/current/theme.
#
# Upstream generates this directory imperatively: `omarchy-theme-set` copies
# themes/<name>/, renders default/themed/*.tpl against the theme's
# colors.toml, and moves the result into place. That renderer
# (`omarchy-theme-set-templates`) is pure bash, awk and sed over files in the
# tree -- no network, no package manager -- so it runs just as well inside a
# derivation, and running it here rather than at login is what makes the
# active theme a property of the system generation instead of user state.
#
# The tradeoff: `omarchy theme set` at runtime no longer works, because the
# rendered tree is a read-only store path. Changing themes means changing
# `omarchy.theme` and rebuilding. See [[omarchy-nixos-module]].
{
  lib,
  runCommandLocal,
  bash,
  coreutils,
  gnused,
  gawk,
  gnugrep,
}: omarchy: name:
runCommandLocal "omarchy-theme-${name}" {
  nativeBuildInputs = [bash coreutils gnused gawk gnugrep];

  meta = {
    description = "Omarchy ${name} theme, rendered from its colors.toml";
  };
} ''
  omarchyPath="${omarchy}/${omarchy.omarchyPath}"
  themeSource="$omarchyPath/themes/${name}"

  if [ ! -d "$themeSource" ]; then
    echo "omarchy: no such theme '${name}' in $omarchyPath/themes" >&2
    exit 1
  fi

  # The renderer addresses its input and output through $HOME, so give it a
  # scratch home laid out the way a real one would be.
  export HOME="$NIX_BUILD_TOP/home"
  export OMARCHY_PATH="$omarchyPath"
  export PATH="$omarchyPath/bin:$PATH"

  staging="$HOME/.local/state/omarchy/current/next-theme"
  mkdir -p "$staging"
  cp -rL "$themeSource"/. "$staging/"
  chmod -R u+w "$staging"

  bash "$omarchyPath/bin/omarchy-theme-set-templates"

  cp -r "$staging" "$out"

  # `omarchy-theme-current` and the shell read the active theme's name from
  # a sibling file, which the staging directory itself never carries.
  echo -n "${name}" > "$out/.theme-name"
''
