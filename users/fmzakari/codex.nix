# Codex shares host instructions and skills with Claude Code.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  agentSettings = import ./agent-settings.nix;
  codex = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;

  # Settings Home Manager owns: Full access, no command approval prompts, a
  # CLAUDE.md fallback, and the native status line. Limits show remaining
  # allowance and are omitted when unavailable.
  settings = {
    approval_policy = "never";
    project_doc_fallback_filenames = ["CLAUDE.md"];
    sandbox_mode = "danger-full-access";
    "tui.status_line" = [
      "model-with-reasoning"
      "context-remaining"
      "five-hour-limit"
      "weekly-limit"
      "estimated-thread-cost"
    ];
  };

  # `-c key=value` parses the value as TOML, and JSON scalars and string
  # arrays are valid TOML, so JSON encoding is enough.
  settingsArgs =
    lib.concatMapStringsSep " "
    (name: "-c ${lib.escapeShellArg "${name}=${builtins.toJSON settings.${name}}"}")
    (lib.attrNames settings);

  codexWithSettings = pkgs.symlinkJoin {
    name = "codex-with-settings";
    inherit (codex) version meta;
    paths = [codex];
    postBuild = ''
      rm $out/bin/codex
      cat > $out/bin/codex <<'EOF'
      #!${pkgs.bash}/bin/bash
      # Every subcommand takes the overrides, including the utility ones that
      # reject --profile.
      exec ${lib.getExe codex} ${settingsArgs} "$@"
      EOF
      chmod +x $out/bin/codex
    '';
  };
  configDir =
    if config.home.preferXdgDirectories
    then "${config.xdg.configHome}/codex"
    else "${config.home.homeDirectory}/.codex";
in {
  programs.codex = {
    enable = true;
    package = codexWithSettings;

    # release-25.11 calls this custom-instructions; newer Home Manager calls
    # it context. Both write the global AGENTS.md.
    custom-instructions = agentSettings.instructions;

    # Leave config.toml writable and unmanaged: Codex persists project trust
    # and interactive preferences to the highest-priority config file it
    # loaded, and anything Nix writes is a read-only store symlink. A profile
    # file has the same problem, which is why the settings above are CLI
    # overrides instead.
  };

  home.file =
    lib.mapAttrs' (name: source:
      lib.nameValuePair ".agents/skills/${name}" {inherit source;})
    agentSettings.skills
    // {
      # Equivalent to Claude's Bash(agent-browser:*) allow rule. Keep a
      # separate file so Codex can still append approvals to default.rules.
      "${configDir}/rules/agent-browser.rules".text = ''
        prefix_rule(
            pattern = ["agent-browser"],
            decision = "allow",
            match = ["agent-browser snapshot", "agent-browser open https://example.com"],
            not_match = ["echo agent-browser"],
        )
      '';
    };
}
