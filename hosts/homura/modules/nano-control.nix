# =============================================================================
# Nano CONTROL PLANE (the brain: LLM loop, session, memory, compaction).
# -----------------------------------------------------------------------------
# Part of the control-plane / executor split. This host runs the loop; the
# tool executor runs on reef (services.nano-executor) and is reached over the
# private veth. If reef dies, the control plane stays up — nano keeps her
# session/memory and is still reachable over Discord, she just loses hands
# (shell/file/image tools) until the executor reconnects.
#
# SECURITY: this process runs NO tools. All shell/file ACE lives on the reef
# executor, sandboxed in the nspawn container. Do not add a local tool client
# here — that would hand arbitrary code execution to homura.
#
# MIGRATION (do before first switch, or nano wakes up empty + handless):
#   1. Copy nano's durable state from the reef container to /var/lib/nano here:
#        memories/  soul.md  nano.db  metrics.db  control/
#   2. Provision the shared token secret on BOTH hosts:
#        secrets/nano-executor-token.age  (recipients: homura + reef)
#   3. Point agents.nano.client at the reef executor's veth address:port.
# =============================================================================
{ config, lib, self, pkgs, ... }:
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

# reef executor, reachable over the private container veth (see
# hosts/homura/modules/coral-container.nix: localAddress 10.233.1.2).
executorEndpoint = "http://10.233.1.2:4221";
in
{
age.secrets.nanoSecrets = {
file  = "${self}/secrets/coral-secrets.toml.age";
mode  = "0400";
owner = config.services.nano.user;
};

age.secrets.bridgetClientKey = {
file  = "${self}/secrets/bridget-client-key.age";
mode  = "0400";
owner = config.services.nano.user;
};

# Shared bearer token authenticating the control plane -> reef executor.
# Must be encrypted for BOTH homura and reef (same plaintext both sides).
age.secrets.nanoExecutorToken = {
file  = "${self}/secrets/nano-executor-token.age";
mode  = "0400";
owner = config.services.nano.user;
};

services.nano = {
enable      = true;
secretsFile = config.age.secrets.nanoSecrets.path;

# Authenticate to the remote executor with the shared token.
executorTokenFile = config.age.secrets.nanoExecutorToken.path;

agents.nano = {
client = executorEndpoint;
};

settings = {
server.port = 4220;
agent = {
name = "nano";
env  = "default";
boredom_wake_min = 0;
git_upstream_nag = true;
};

llm_bridge_url = "https://bridget.on-her.computer/v1";
llm_bridge_api_key_file = config.age.secrets.bridgetClientKey.path;

tools.hashline = true;

discord.owner_id = "257329343301156886";

# computer_use drives the Xvfb display that lives on the reef
# executor; the loop reaches it through the executor's shell/computer
# tools, not a local X server.
computer_use = {
enabled = true;
display = ":99";
};

image_tool.max_bytes = 5000000;

models = {
umans-glm-5_2 = basePreset // {
model            = "umans-glm-5.2";
thinking_effort  = "xhigh";
vision           = false;
};

umans-kimi = basePreset // {
model            = "umans-kimi-k2.7";
thinking_effort  = "xhigh";
vision           = true;
nudge_on_no_tool = true;
};

umans-flash = basePreset // {
model            = "umans-flash";
thinking_effort  = "xhigh";
vision           = true;
enable_thinking  = true;
bridge           = true;
tool_choice      = "required";
};

claude = claudePreset // {
model           = "claude-opus-4-8";
thinking_effort = "xhigh";
};

claude-opus-mid = claudePreset // {
model           = "claude-opus-4-8";
thinking_effort = "medium";
};

claude-low = claudePreset // {
model           = "claude-sonnet-5";
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
provider         = "openrouter";
model            = "zai-org/glm-5.2";
tool_choice      = "required";
thinking_effort  = "xhigh";
};

gemini-embedding = {
provider   = "openai";
model      = "google/gemini-embedding-2-preview";
base_url   = "https://openrouter.ai/api/v1";
dimensions = 3072;
};
};

model      = { preset = "claude";           };
fallback   = { preset = "gpt-terra";        };
summary    = { preset = "gpt-luna-low";     };
embeddings = { preset = "gemini-embedding"; };

subagents = [
{
name = "explore";
model = "gpt-luna";
system_prompt = "You are an exploratory agent. Your goal is to investigate thoroughly to achieve the task assigned to you by your calling agent.";
enabled_tools = [ "shell" "read_file" ];
}
{
name = "coder";
model = "gpt-luna";
system_prompt = "You are a focused coding agent. Write, edit, and test code. Verify your work compiles.";
enabled_tools = [ "shell" "read_file" "edit_file" "write_file" ];
}
{
name = "vision";
model = "gpt-luna";
system_prompt = "You are a focused agent with vision.";
enabled_tools = [ "image_tool" "shell" "read_file" "edit_file" "write_file" ];
}
{
name = "computer";
model = "gpt-luna";
system_prompt = "You are a computer use agent. You can take screenshots, click, type, scroll, and drag on a graphical desktop. Always screenshot first to see the current state before acting. Work step by step: observe, act, observe again.";
enabled_tools = [ "computer" "image_tool" "shell" "read_file" "edit_file" "write_file" ];
}
];
};
};
}
