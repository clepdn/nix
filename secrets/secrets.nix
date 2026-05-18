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
	systemKeys = map(host: builtins.readFile ./publicKeys/root_${host}.pub) hosts;
	userKeys = map(user: builtins.readFile ./publicKeys/${user}.pub) users;
	keys = systemKeys ++ userKeys;
	# Keys for the nix remote builder secret — client machines + admin keys
	# (homura is the server so its root key is not strictly needed, but included for admin)
	nixBuilderKeys = [
		(builtins.readFile ./publicKeys/root_sayaka.pub)
		(builtins.readFile ./publicKeys/root_madoka.pub)
		(builtins.readFile ./publicKeys/root_homura-v.pub)
		(builtins.readFile ./publicKeys/callie_sayaka.pub)
		(builtins.readFile ./publicKeys/callie_madoka.pub)
		(builtins.readFile ./publicKeys/callie_homura-v.pub)
	];
	in {
		"minio.age".publicKeys = keys;
		"muliphein.age".publicKeys = keys;
		"muliphein-pskey.age".publicKeys = keys;
		"gluetun.age".publicKeys = keys;
		"authelia-jwt.age".publicKeys = keys;
		"authelia-session.age".publicKeys = keys;
		"authelia-storagekey.age".publicKeys = keys;
		"authelia-users.yml.age".publicKeys = keys;
		"authentik.env.age".publicKeys = keys;
		"webhook.age".publicKeys = keys;
		"cloudflare-dns.age".publicKeys = keys;
		"grafana-secret-key.age".publicKeys = keys;
		"home-assistant-secrets.age".publicKeys = keys;
		"pds.env.age".publicKeys = keys;
		"slugtan.env.age".publicKeys = keys;
		"llama-api-key.age".publicKeys = keys;
		"letta-password.age".publicKeys = keys;
		"happy.env.age".publicKeys = keys;
		"nix-remote-builder-key.age".publicKeys = nixBuilderKeys;
	}

