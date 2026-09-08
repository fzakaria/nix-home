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
  profileName = "nix-home";
  codexWithProfile = pkgs.symlinkJoin {
    name = "codex-with-profile";
    inherit (codex) version meta;
    paths = [codex];
    postBuild = ''
      rm $out/bin/codex
      cat > $out/bin/codex <<'EOF'
      #!${pkgs.bash}/bin/bash
      # Utility commands do not accept a profile. Runtime commands and bare
      # prompts use the Home Manager profile.
      case "''${1-}" in
        agents|login|logout|plugin|mcp-server|app-server|remote-control|completion|update|doctor|apply|a|migrate-rollouts|cloud|exec-server|features|help)
          exec ${lib.getExe codex} "$@"
          ;;
        debug)
          if [[ "''${2-}" != prompt-input ]]; then
            exec ${lib.getExe codex} "$@"
          fi
          ;;
      esac
      exec ${lib.getExe codex} --profile ${profileName} "$@"
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
    package = codexWithProfile;

    # release-25.11 calls this custom-instructions; newer Home Manager calls
    # it context. Both write the global AGENTS.md.
    custom-instructions = agentSettings.instructions;

    # Leave config.toml writable: Codex stores project trust and interactive
    # preferences there. The profile configures Codex's native status line;
    # Claude's ccusage script and LSP plugin have Claude-specific interfaces.
  };

  home.file =
    lib.mapAttrs' (name: source:
      lib.nameValuePair ".agents/skills/${name}" {inherit source;})
    agentSettings.skills
    // {
      # Codex >= 0.134 reads profiles from separate files. The pinned Home
      # Manager release has no profiles option, so generate the file directly.
      "${configDir}/${profileName}.config.toml".source = (pkgs.formats.toml {}).generate "codex-profile.toml" {
        sandbox_mode = "danger-full-access";
        approval_policy = "never";
        project_doc_fallback_filenames = ["CLAUDE.md"];
        # Limits show remaining allowance and are omitted when unavailable.
        tui.status_line = [
          "model-with-reasoning"
          "context-remaining"
          "five-hour-limit"
          "weekly-limit"
          "estimated-thread-cost"
        ];
      };

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
