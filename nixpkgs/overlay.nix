self: super:
{
  # We want to use the yubikey-agent so disable gnome's ssh-agent
  gnome = super.gnome.overrideScope (gfinal: gprev: {
    gnome-keyring = gprev.gnome-keyring.overrideAttrs (oldAttrs: {
      configureFlags = oldAttrs.configureFlags or [ ] ++ [
        "--disable-ssh-agent"
      ];
    });
  });
}
