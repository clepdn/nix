{ config, self, ... }:
let
  basePreset = {
    enable_thinking = true;
    vision = true;
    bridge = true;
    tool_choice = "required";
    deep_archive = true;
    compaction_strategy = "companion";
    journal_before_compaction = true;
    idle_compaction_minutes = 30;
  };
  claudePreset = basePreset // {
    vision = true;
    compact_trigger_tokens = 240000;
    preserve_prompt_cache = true;
    idle_compaction_minutes = 50;
  };
  oaiPreset = claudePreset // {
    compaction_strategy = "remote";
  };
  gpt-luna = oaiPreset // {
    model = "gpt-5.6-luna";
    thinking_effort = "xhigh";
  };
in
{
  age.secrets.nanoSecrets = {
    file = "${self}/secrets/coral-secrets.toml.age";
    mode = "0400";
    owner = config.services.nano.user;
  };

  age.secrets.bridgetClientKey = {
    file = "${self}/secrets/bridget-client-key.age";
    mode = "0400";
    owner = config.services.nano.user;
  };

  # Shared bearer token authenticating the control plane -> reef executor.
  # Must be encrypted for BOTH homura and reef (same plaintext both sides).
  age.secrets.nanoExecutorToken = {
    file = "${self}/secrets/nano-executor-token.age";
    mode = "0400";
    owner = config.services.nano.user;
  };

  services.nano = {
    enable = true;
    secretsFile = config.age.secrets.nanoSecrets.path;

    # Authenticate to the remote executor with the shared token.
    executorTokenFile = config.age.secrets.nanoExecutorToken.path;

    agents.nano.client = "http://10.233.1.2:4221";

    settings = {
      server.port = 4220;

      agent = {
        name = "nano";
        env = "default";
        boredom_wake_min = 0;
        git_upstream_nag = true;
      };

      llm_bridge_url = "https://bridget.on-her.computer/v1";
      llm_bridge_api_key_file = config.age.secrets.bridgetClientKey.path;

      tools.hashline = true;

      discord.owner_id = "257329343301156886";

      # The action runs on the reef executor (capability `computer`); `display`
      # names the Xvfb that lives there, not anything on homura.
      computer_use = {
        enabled = true;
        display = ":99";
      };

      image_tool.max_bytes = 5000000;

      models = {
        umans-flash = basePreset // {
          model = "umans-flash";
          thinking_effort = "xhigh";
          vision = true;
          enable_thinking = true;
          bridge = true;
          tool_choice = "required";
        };

        claude = claudePreset // {
          model = "claude-opus-4-8";
          thinking_effort = "xhigh";
        };

        claude-opus-mid = claudePreset // {
          model = "claude-opus-4-8";
          thinking_effort = "medium";
        };

        claude-low = claudePreset // {
          model = "claude-sonnet-5";
          thinking_effort = "medium";
        };

        gpt-luna = gpt-luna;

        gpt-luna-low = oaiPreset // {
          thinking_effort = "low";
        };

        gpt-terra = oaiPreset // {
          model = "gpt-5.6-terra";
          thinking_effort = "high";
        };
        gpt-sol = oaiPreset // {
          model = "gpt-5.6-sol";
          thinking_effort = "high";
        };

        glm-openrouter = {
          provider = "openrouter";
          model = "zai-org/glm-5.2";
          tool_choice = "required";
          thinking_effort = "xhigh";
        };

        gemini-embedding = {
          provider = "openai";
          model = "google/gemini-embedding-2-preview";
          base_url = "https://openrouter.ai/api/v1";
          dimensions = 3072;
        };
      };

      # Both routes stay on Bridget's subscription-backed Codex accounts.
      # Never fail over to OpenRouter/Umans pay-per-token providers.
      model = {
        preset = "gpt-terra";
      };
      fallback = {
        preset = "gpt-sol";
      };
      summary = {
        preset = "gpt-luna-low";
      };
      embeddings = {
        preset = "gemini-embedding";
      };

      subagents = [
        {
          name = "explore";
          model = "gpt-luna";
          system_prompt = "You are an exploratory agent. Your goal is to investigate thoroughly to achieve the task assigned to you by your calling agent.";
          enabled_tools = [
            "shell"
            "read_file"
          ];
        }
        {
          name = "coder";
          model = "gpt-luna";
          system_prompt = "You are a focused coding agent. Write, edit, and test code. Verify your work compiles.";
          enabled_tools = [
            "shell"
            "read_file"
            "edit_file"
            "write_file"
          ];
        }
        {
          name = "vision";
          model = "gpt-luna";
          system_prompt = "You are a focused agent with vision.";
          enabled_tools = [
            "image_tool"
            "shell"
            "read_file"
            "edit_file"
            "write_file"
          ];
        }
        {
          name = "computer";
          model = "gpt-luna";
          system_prompt = "You are a computer use agent. You can take screenshots, click, type, scroll, and drag on a graphical desktop. Always screenshot first to see the current state before acting. Work step by step: observe, act, observe again.";
          enabled_tools = [
            "computer"
            "image_tool"
            "shell"
            "read_file"
            "edit_file"
            "write_file"
          ];
        }
      ];
    };
  };
}
