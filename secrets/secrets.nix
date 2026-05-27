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
		"homura"
	];
	systemSSHKeys = map(host: builtins.readFile ./publicKeys/root_${host}.pub) hosts;
	userSSHKeys   = map(user: builtins.readFile ./publicKeys/${user}.pub) users;
	pqKeys        = map(key:  builtins.readFile ./publicKeys/${key}_pq.pub) pq_pubkeys;
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
		"slugtan.env.age".publicKeys = DEPRECATED_sshKeys;
		"llama-api-key.age".publicKeys = DEPRECATED_sshKeys;
		"letta-password.age".publicKeys = DEPRECATED_sshKeys;
		"happy.env.age".publicKeys = DEPRECATED_sshKeys;
		"nix-remote-builder-key.age".publicKeys = DEPRECATED_sshKeys;
		"piclaw-keychain-key.env.age".publicKeys = DEPRECATED_sshKeys;
		"garage-rpc-secret.age".publicKeys = DEPRECATED_sshKeys;
		"garage-admin-token.age".publicKeys = DEPRECATED_sshKeys;
		"garage-metrics-token.age".publicKeys = DEPRECATED_sshKeys;
		"autobrr-session.age".publicKeys = DEPRECATED_sshKeys;

		"hermes.env.age".publicKeys = keys ++ userSSHKeys;
	}

