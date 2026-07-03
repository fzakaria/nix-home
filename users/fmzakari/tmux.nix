{pkgs, ...}: {
  # tmux — a terminal multiplexer.
  #
  # tmux lets you run many terminals inside one, split into panes, keep
  # sessions alive after you disconnect (great over SSH), and detach/reattach
  # at will.
  #
  # Home Manager reference (every option below is documented here):
  #   https://github.com/nix-community/home-manager/blob/master/modules/programs/tmux.nix
  #
  # A few tmux vocabulary words used throughout the comments:
  #   - session : a collection of windows; survives detaching (`tmux detach`)
  #   - window  : like a browser tab, fills the whole screen
  #   - pane    : a split *within* a window
  #   - prefix  : the "leader" key you press before any tmux command.
  programs.tmux = {
    enable = true;
    # Use the newer unstable tmux to match the rest of your packages.
    package = pkgs.unstable.tmux;

    # ---- Core behaviour -----------------------------------------------------

    # Start numbering windows/panes at 1 instead of 0. The 0 key is a long
    # reach on the keyboard, so `prefix 1` selecting the first window is nicer.
    baseIndex = 1;

    # Changes prefix to Ctrl-a
    # shortcut = "a";

    # Use vi-style keybindings in copy mode (the mode you enter to scroll back
    # and select text). If you prefer emacs bindings, set this to "emacs".
    keyMode = "vi";

    # Enable mouse support: click to select panes/windows, drag borders to
    # resize, and scroll with the wheel. Turn off if you want pure keyboard.
    mouse = true;

    # How long tmux waits (ms) after you press Escape before deciding it was a
    # lone Escape and not the start of a key sequence. The 500ms default makes
    # vim/helix feel laggy when hitting Esc, so we drop it to near-zero.
    escapeTime = 10;

    # Scrollback buffer: how many lines of history tmux keeps per pane.
    # The default (2000) is small; 50k is comfortable and cheap.
    historyLimit = 50000;

    # The $TERM value tmux advertises to programs running inside it.
    # "tmux-256color" is the modern, correct choice for 256-color + italics.
    terminal = "tmux-256color";

    # Home Manager puts tmux-sensible at the top of the config by default
    # (this is the `sensibleOnTop` option, on by default). tmux-sensible is a
    # small set of "everyone agrees on these" defaults, so we let it stay.

    # ---- Plugins ------------------------------------------------------------
    # Home Manager installs these declaratively — no need for TPM (the tmux
    # plugin manager) or any `prefix + I` install step.
    plugins = with pkgs.tmuxPlugins; [
      # Dracula theme, matching your bat/ghostty/helix/zellij setup.
      # It draws the status bar at the bottom.
      #
      # The @dracula-* options MUST be set *before* the plugin's own
      # run-shell fires, otherwise dracula reads them while still unset and
      # falls back to its defaults (battery/network/weather). Home Manager
      # emits a plugin's per-plugin `extraConfig` right before that plugin's
      # run-shell — the global `extraConfig` below comes *after* it — so the
      # options live here rather than at the bottom. See:
      #   https://github.com/dracula/tmux
      {
        plugin = dracula;
        extraConfig = ''
          set -g @dracula-show-powerline true
          set -g @dracula-plugins "cpu-usage ram-usage time"
          set -g @dracula-show-left-icon session
        '';
      }

      # Copy to the *system* clipboard from copy mode. Uses xclip under X11,
      # which you already install. In copy mode: `v` to start selecting,
      # `y` to yank into the clipboard.
      yank
    ];

    # ---- Everything else ----------------------------------------------------
    # Options without a dedicated Home Manager setting go here as raw tmux.conf.
    extraConfig = ''
      # === Claude Code integration =========================================
      # Recommended by https://code.claude.com/docs/en/terminal-config#configure-tmux
      #
      # allow-passthrough: lets escape sequences from programs inside tmux
      # reach the outer terminal. Without it, Claude Code's desktop
      # notifications and progress bar get swallowed by tmux.
      set -g allow-passthrough on
      #
      # extended-keys: lets tmux tell apart key combos it normally can't, most
      # importantly Shift+Enter vs a plain Enter — so Shift+Enter inserts a
      # newline in Claude Code instead of submitting.
      set -s extended-keys on
      set -as terminal-features 'xterm*:extkeys'

      # === True color ======================================================
      # Advertise 24-bit ("true") color to programs so themes render exactly.
      # RGB is the capability flag; Tc is the older alias some apps look for.
      set -ga terminal-overrides ",*256col*:Tc"
      set -ga terminal-features  ",*256col*:RGB"

      # === Focus + activity ================================================
      # Tell programs (vim/helix) when the terminal gains/loses focus so their
      # autoread / focus features work.
      set -g focus-events on

      # === Splitting panes =================================================
      # Defaults are prefix-" and prefix-% which are unintuitive. Rebind to
      # visually mnemonic keys, and open the split in the *current* directory.
      #   prefix |  -> split left/right (vertical divider)
      #   prefix -  -> split top/bottom (horizontal divider)
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      # New windows also inherit the current directory.
      bind c new-window -c "#{pane_current_path}"

      # === Moving between panes (vim style) ================================
      # prefix + h/j/k/l to move left/down/up/right between panes.
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # === Resizing panes ==================================================
      # prefix + H/J/K/L (hold to repeat, thanks to -r) to resize.
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # === Reload config ===================================================
      # prefix + r  ->  re-source this file without restarting tmux.
      # (After `home-manager switch`, the file lives at ~/.config/tmux/tmux.conf)
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded"

      # === Copy-mode niceties (vi style) ===================================
      # In copy mode: v starts a selection, y copies it (yank plugin handles
      # the system clipboard). Feels like vim's visual mode.
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-selection-and-cancel

      # === Zoom indicator ==================================================
      # When you zoom a pane to fullscreen (prefix + z), it's easy to forget
      # the window is holding other hidden panes. Append a magnifying glass to
      # the active window's status entry while it's zoomed. `set -ga` *appends*
      # to whatever Dracula already set window-status-current-format to, so we
      # keep Dracula's styling and just tack the glass on the end. This runs
      # after Dracula's run-shell (global extraConfig comes last), so the
      # append lands on top of Dracula's value.
      set -ga window-status-current-format "#{?window_zoomed_flag, 🔍,}"

      # NOTE: Dracula theme widgets (@dracula-plugins etc.) are configured up
      # in the plugins list, not here — they must be set *before* the plugin's
      # run-shell runs. See the comment there for why.
    '';
  };
}
