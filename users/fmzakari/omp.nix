{
  lib,
  pkgs,
  ...
}: let
  # Chrome for the Playwright MCP server to attach to. Playwright only searches
  # standard FHS locations, so the store path is passed with --executable-path.
  chrome = lib.getExe pkgs.google-chrome;
in {
  # omp reads its configuration from ~/.omp/agent. These files are managed here
  # so the setup survives a reinstall. Edits made by omp itself are overwritten
  # on the next home-manager switch.
  home.file = {
    # The built-in browser tool is off because omp drops browser MCP servers at
    # config load while it is on. See docs/mcp-config.md in can1357/oh-my-pi.
    ".omp/agent/config.yml".text = ''
      setupVersion: 3
      browser:
        enabled: false
    '';

    ".omp/agent/mcp.json".text = builtins.toJSON {
      "$schema" = "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json";
      mcpServers.playwright = {
        type = "stdio";
        command = lib.getExe pkgs.playwright-mcp;
        args = [
          "--extension"
          "--executable-path"
          chrome
        ];
      };
    };

    # The API key is read from the UNLID_API_KEY environment variable, not
    # stored in this file.
    ".omp/agent/models.yml".text = ''
      providers:
        unlid:
          baseUrl: https://api.unlid.ai/v1
          api: openai-completions
          apiKey: UNLID_API_KEY
          models:
            - id: kimi-k3.1-pro-abliterated
              name: Kimi K3.1 Pro (abliterated)
            - id: deepseek-v4.1-flash-abliterated
              name: DeepSeek V4.1 Flash (abliterated)
            - id: glm-5.3-flash-abliterated
              name: GLM 5.3 Flash (abliterated)
    '';
  };
}
