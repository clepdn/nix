let hosts = [
		"megatron"
		"madoka"
		"homura-v"
	];
	users = [
		"callie_megatron"
		"callie_madoka"
		"callie_homura-v"
	];
	systemKeys = map(host: builtins.readFile ./publicKeys/root_${host}.pub) hosts;
	userKeys = map(user: builtins.readFile ./publicKeys/${user}.pub) users;
	keys = systemKeys ++ userKeys;
	in {
		"minio.age".publicKeys = keys;
		"tailscale.age".publicKeys = keys;
		"muliphein.age".publicKeys = keys;
		"muliphein-pskey.age".publicKeys = keys;
		"gluetun.age".publicKeys = keys;
		"authelia-jwt.age".publicKeys = keys;
		"authelia-session.age".publicKeys = keys;
		"authelia-storagekey.age".publicKeys = keys;
		"authelia-users.yml.age".publicKeys = keys;
		"authentik.env.age".publicKeys = keys;
	}

