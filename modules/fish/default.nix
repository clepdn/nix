{ ... }:
{
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.fish = {
    enable = true;

    functions = {
      fish_prompt = ''
        set -l cwd (prompt_pwd)

        set -l cwd_color blue
        if test "$PWD" != "$HOME"
            set cwd_color ffb3c6
        end

        set -l git_branch (command git symbolic-ref --short HEAD 2>/dev/null)
        if test -z "$git_branch"
            set git_branch (command git rev-parse --short HEAD 2>/dev/null)
        end

        set_color ff6b9d
        echo -n "୨୧"
        set_color white
        echo -n " $USER "
        set_color red
        echo -n "♡"
        set_color white
        echo -n " $hostname "
        set_color ff6b9d
        echo -n "୨୧"
        set_color white
        echo -n " ⋆ "
        set_color $cwd_color
        echo -n "$cwd"
        set_color white
        echo -n " ⋆"

        if test -n "$git_branch"
            set -l git_color yellow
            if command git status --porcelain 2>/dev/null | string length -q
                set git_color magenta
            end
            set_color $git_color
            echo -n "  $git_branch"
            set_color white
            echo -n " ✧"
        end

        echo -n " "
      '';

      net.body = "nix run nixpkgs#$argv[1] -- $argv[2..-1]";
    };

    shellAliases = {
      # editor
      vi = "nvim";
      # ls
      l  = "ls -alh";
      ll = "ls -l";
      ls = "ls --color=tty";
      # git
      gf = "git fetch";
      gp = "git pull --ff-only";
      gs = "git status";
    };

    interactiveShellInit = ''
      set -g fish_color_autosuggestion     brblack
      set -g fish_color_cancel             -r
      set -g fish_color_command            blue
      set -g fish_color_comment            red
      set -g fish_color_cwd               green
      set -g fish_color_cwd_root          red
      set -g fish_color_end               green
      set -g fish_color_error             brred
      set -g fish_color_escape            brcyan
      set -g fish_color_history_current   --bold
      set -g fish_color_host              normal
      set -g fish_color_host_remote       yellow
      set -g fish_color_normal            normal
      set -g fish_color_operator          brcyan
      set -g fish_color_param             cyan
      set -g fish_color_quote             yellow
      set -g fish_color_redirection       'cyan --bold'
      set -g fish_color_search_match      'white --background=brblack'
      set -g fish_color_selection         'white --bold --background=brblack'
      set -g fish_color_status            red
      set -g fish_color_user              brgreen
      set -g fish_color_valid_path        --underline
      set -g fish_pager_color_completion  normal
      set -g fish_pager_color_description 'yellow -i'
      set -g fish_pager_color_prefix      'normal --bold --underline'
      set -g fish_pager_color_progress    'brwhite --background=cyan'
      set -g fish_pager_color_selected_background -r
    '';
  };
}
