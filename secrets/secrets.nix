/*
let
	callie = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6hUWuV72dWU5P6MkmAKDbKsimS8sOL+D/Dm+2FxVXJ callie@megatron";
	homura-v = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfMza/8Zl74EwMcdRv0FVfV68NBXIAN74OOsPlhNCZ4 root@nixos";
*/
	
/*

let hosts = [
		"megatron",
		"xps",
		"homura-v"
	];
	users = [
		"callie_megatron",
		"callie_xps",
		"callie_homura-v",
		# "root_homura-v", # Not what you're supposed to do?
	];
	systemKeys = builtins.map(host: builtins.readFile ./publicKeys/root_${host}.pub) hosts;
	userKeys = builtins.map(user: builtins.readFile ./publicKeys/${user}.pub) users;
	keys = systemKeys ++ userKeys;
	in {
		
	};

*/
