{ config, ... }: {
  age.secrets.hermes-env = {
    file = ../../../secrets/hermes.env.age;
    # hermes reads this as an env file; the hermes user needs read access
    owner = "hermes";
    group = "hermes";
    mode = "0400";
  };

  services.hermes-agent = {
    enable = true;

    settings = {
      model = {
        # Native DeepSeek API — no aggregator middleman.
        # V3 (fast/cheap): deepseek-chat
        # V4 Pro (reasoning): deepseek-v4-pro
        # Legacy reasoner (R1): deepseek-reasoner
        default = "deepseek-v4-pro";
        base_url = "https://api.deepseek.com/v1";
      };
      toolsets = [ "all" ];
      terminal = {
        backend = "local";
        timeout = 180;
      };
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
    };

    # API keys live in the agenix-managed secret (never in the Nix store).
    # The file should contain lines like:
    #   OPENROUTER_API_KEY=sk-or-...
    environmentFiles = [ config.age.secrets.hermes-env.path ];

    # Container mode: lets the agent apt/pip/npm-install tools that persist
    # across restarts and rebuilds — appropriate for a coding agent.
    container = {
      enable = true;
      # Gives callie a ~/.hermes symlink into the service state dir so the
      # host-side `hermes` CLI shares sessions, memory, and config with the
      # gateway service.
      hostUsers = [ "callie" ];
    };

    # Puts `hermes` on the system PATH and sets HERMES_HOME system-wide.
    addToSystemPackages = true;
  };
}
