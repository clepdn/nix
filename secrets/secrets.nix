let hosts = [
		"megatron"
		"madoka"
		"homura-v"
		"sayaka"
	];
	users = [
		"callie_megatron"
		"callie_madoka"
		"callie_homura-v"
		"callie_sayaka"
	];
	pq_pubkeys = [
		"callie_megatron_pq"
		"callie_homura_pq"
		"homura_pq"
		"madoka_pq"
		"callie_madoka_pq"
	];

	coral_keys = [
		"reef_pq"
		"coral_reef_pq"
	];

	readKeys = files: map(key: builtins.readFile ./publicKeys/${key}.pub) files;

	
	systemSSHKeys = map(host: builtins.readFile ./publicKeys/root_${host}.pub) hosts;
	userSSHKeys   = readKeys users;
	coralKeys     = readKeys coral_keys;
	pqKeys        = readKeys pq_pubkeys;

	DEPRECATED_sshKeys = systemSSHKeys ++ userSSHKeys;
	keys = pqKeys;

	in {
		"minio.age".publicKeys = DEPRECATED_sshKeys;
		"muliphein.age".publicKeys = DEPRECATED_sshKeys;
		"muliphein-pskey.age".publicKeys = DEPRECATED_sshKeys;
		"gluetun.age".publicKeys = DEPRECATED_sshKeys;
		"authelia-jwt.age".publicKeys = DEPRECATED_sshKeys;
		"authelia-session.age".publicKeys = DEPRECATED_sshKeys;
		"authelia-storagekey.age".publicKeys = DEPRECATED_sshKeys;
		"authelia-users.yml.age".publicKeys = DEPRECATED_sshKeys;
		"authentik.env.age".publicKeys = DEPRECATED_sshKeys;
		"webhook.age".publicKeys = DEPRECATED_sshKeys;
		"cloudflare-dns.age".publicKeys = DEPRECATED_sshKeys;
		"grafana-secret-key.age".publicKeys = DEPRECATED_sshKeys;
		"home-assistant-secrets.age".publicKeys = DEPRECATED_sshKeys;
		"pds.env.age".publicKeys = DEPRECATED_sshKeys;
		"llama-api-key.age".publicKeys = DEPRECATED_sshKeys;
		"letta-password.age".publicKeys = DEPRECATED_sshKeys;
		"happy.env.age".publicKeys = DEPRECATED_sshKeys;
		"nix-remote-builder-key.age".publicKeys = DEPRECATED_sshKeys;
		"piclaw-keychain-key.env.age".publicKeys = DEPRECATED_sshKeys;
		"garage-rpc-secret.age".publicKeys = DEPRECATED_sshKeys;
		"garage-admin-token.age".publicKeys = DEPRECATED_sshKeys;
		"garage-metrics-token.age".publicKeys = DEPRECATED_sshKeys;
		"autobrr-session.age".publicKeys = DEPRECATED_sshKeys;
		# When adding new secrets, do not use DEPRECATED_sshKeys. 
		# We now have enough post-quantum keys for the keys object to be fully functional on every host that matters.
		# Any host that doesn't have pq keys setup yet is a provisioning issue that will be dealt with later, since they're all mostly on ancient NixOS versions anyways.
		# the DEPRECATED_sshKeys object mostly serves as a reminder that I need to rotate the secret while it's re-encrypted with a post-quantum key, as simply re-encrypting it defeats the entire purpose. The x25519 encrypted value is already in the git history and/or downloaded by the chinese/NSA

		"comail-sasl.age".publicKeys = keys;
		"mail-passwd-callie.age".publicKeys = keys;

		# coral's secrets
		"coral.env.age".publicKeys = keys ++ readKeys [ "reef_pq" ]; # she can't get this one. this has real api keys
		"slskd.env.age".publicKeys = keys ++ readKeys [ "coral_reef_pq" ];
		"coral-secrets.toml.age".publicKeys = keys ++ readKeys [ "coral_reef_pq" ] ++ readKeys [ "reef_pq" ];
		"coral-webhook-token.age".publicKeys = keys ++ coralKeys;

		# Per-host nix binary-cache signing keys.
		# Only the owning host needs to decrypt (used at activation to sign
		# store paths locally so nix-copy-closure works without trusted-users).
		"nix-signing-madoka.age".publicKeys   = readKeys [ "madoka_pq"   "callie_madoka_pq"   ];
		"nix-signing-homura.age".publicKeys   = readKeys [ "homura_pq"   "callie_homura_pq"   ];
		"nix-signing-megatron.age".publicKeys = readKeys [ "megatron_pq" "callie_megatron_pq" ];
		"nix-signing-reef.age".publicKeys     = readKeys [ "reef_pq" ];
	}

