{ ... }:
{
  programs.niri.settings = {
    input = {
      keyboard.xkb = { };
      touchpad = {
        tap = true;
        natural-scroll = false;
        accel-speed = -0.2;
        accel-profile = "flat";
      };
      mouse = {
        accel-speed = -0.3;
        accel-profile = "flat";
      };
      focus-follows-mouse.enable = true;
    };

    cursor = {
      theme = "Teto_Cursor";
      size = 32;
    };

    environment = {
    /*
      XDG_MENU_PREFIX = "arch-";
      SSH_ASKPASS = "ksshaskpass";
      SSH_ASKPASS_REQUIRE = "prefer";
    */
      QT_QPA_PLATFORMTHEME = "qt6ct";
    };

    layout = {
      gaps = 0;
      center-focused-column = "never";
      preset-column-widths = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
      ];
      default-column-width.proportion = 0.5;
      focus-ring = {
        enable = false;
        width = 4;
        active.color = "#7fc8ff";
        inactive.color = "#505050";
      };
      border = {
        enable = false;
        width = 4;
        active.color = "#ffc87f";
        inactive.color = "#505050";
        urgent.color = "#9b0000";
      };
      shadow = {
        softness = 30;
        spread = 5;
        offset = { x = 0; y = 5; };
        color = "#0007";
      };
    };

    prefer-no-csd = true;

    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    clipboard.disable-primary = true;

    hotkey-overlay.skip-at-startup = true;

    window-rules = [
      {
        matches = [ { is-window-cast-target = true; } ];
        focus-ring = {
          enable = true;
          width = 4;
          active.color = "#f38ba8";
          inactive.color = "#7d0d2d";
        };
      }
      {
        matches = [ { app-id = "signal"; } ];
        block-out-from = "screencast";
      }
      {
        matches = [ { app-id = "^org\\.wezfurlong\\.wezterm$"; } ];
        default-column-width = { };
      }
      {
        matches = [ { app-id = "firefox$"; title = "^Picture-in-Picture$"; } ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "plasmashell"; } ];
        open-floating = true;
        open-focused = false;
        focus-ring.enable = false;
      }
    ];

  };
}
