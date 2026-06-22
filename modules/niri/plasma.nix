{ ... }:
{
  # plasma-manager owns the Plasma config files (kdeglobals, etc.) on niri
  # hosts that otherwise have no Plasma session to write them. Setting the
  # color scheme here is what makes xdg-desktop-portal-kde report
  # 'prefer-dark' for org.freedesktop.appearance.color-scheme, which is how
  # Chromium-based apps (helium, spotify, discord, electron stuff) pick up
  # dark mode.
  programs.plasma = {
    enable = true;
    workspace = {
      colorScheme = "BreezeDark";
    };
  };
}
