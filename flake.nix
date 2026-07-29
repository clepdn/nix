{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		jovian = {
			url = "github:Jovian-Experiments/Jovian-NixOS";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		zen-browser = {
			url = "github:0xc000022070/zen-browser-flake";
			inputs = {
				nixpkgs.follows = "nixpkgs";
				home-manager.follows = "home-manager"; 
			};
		};
		lanzaboote = {
			url = "github:nix-community/lanzaboote";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		/*
		apple-color-emoji = {
		      url = "github:samuelngs/apple-emoji-linux";
		      inputs.nixpkgs.follows = "nixpkgs";  
		};
		*/
		agenix = {
			url = "github:ryantm/agenix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		nix-minecraft = {
			url = "github:Infinidoge/nix-minecraft";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		nixos-uconsole.url = "github:nixos-uconsole/nixos-uconsole";
		# Expose the Raspberry Pi input pinned by nixos-uconsole. Its packages
		# stay on 25.11 for binary-compatible kernel/cache artifacts, while the
		# system constructor below evaluates against our unstable nixpkgs.
		nixos-raspberrypi.follows = "nixos-uconsole/nixos-raspberrypi";
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		plasma-manager = {
			url = "github:nix-community/plasma-manager";
			inputs = {
				nixpkgs.follows = "nixpkgs";
				home-manager.follows = "home-manager";
			};
		};
		nixvim.url = "github:nix-community/nixvim";
		niri = {
			url = "github:sodiboo/niri-flake";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		flake-utils.url = "github:numtide/flake-utils";
		disko = {
			url = "github:nix-community/disko";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		pi-mono = {
			url = "git+https://tangled.org/did:plc:6sne3swnekt6dtcmfagifvoi";
			inputs = {
				nixpkgs.follows = "nixpkgs";
				flake-utils.follows = "flake-utils";
			};
		};

		direct-vx = {
			url = "git+https://codeberg.org/cowie/direct-vx.git";
			inputs.nixpkgs.follows = "nixpkgs";
			inputs.flake-utils.follows = "flake-utils";
		};
		plymouth-signalis = {
			url = "git+https://codeberg.org/cowie/plymouth-signalis.git";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		coral = {
			url = "git+https://tangled.org/callie.on-her.computer/coral";
			inputs = {
				nixpkgs.follows = "nixpkgs";
				flake-utils.follows = "flake-utils";
			};
		};

		llama-cpp-src = {
			url = "github:AtomicBot-ai/atomic-llama-cpp-turboquant";
			flake = false;
		};
		pavement = {
			url = "git+ssh://git@codeberg.org/cowie/md-site.git?ref=release";
			flake = false;
		};
		quickshell-config = {
			url = "git+https://tangled.org/callie.on-her.computer/quickshell";
			flake = false;
		};

		claude-desktop = {
			url = "github:aaddrick/claude-desktop-debian";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		codex-desktop = {
			url = "github:ilysenko/codex-desktop-linux";
			inputs = {
				nixpkgs.follows = "nixpkgs";
				flake-utils.follows = "flake-utils";
			};
		};
	};

	outputs =
	inputs @ { self, nixpkgs, flake-utils, home-manager, ... }:

	let
		mypkgs = import ./pkgs { pkgs = nixpkgs.legacyPackages.x86_64-linux; lib = nixpkgs.lib; };
		mkHost = host: extraModules: nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs self mypkgs; clib = import ./lib nixpkgs.lib; };
			modules = [
				./hosts/${host}
				inputs.agenix.nixosModules.default
				inputs.home-manager.nixosModules.home-manager
				({ inputs, ... }: {
					home-manager.useGlobalPkgs = true;
					home-manager.extraSpecialArgs = { inherit inputs mypkgs; };
					home-manager.sharedModules = [
						inputs.agenix.homeManagerModules.default
						inputs.plasma-manager.homeManagerModules.plasma-manager
					];
				})
			] ++ extraModules;
		};
	in
	{
		homeConfigurations.callie = home-manager.lib.homeManagerConfiguration {
			pkgs = import nixpkgs {
				system = "x86_64-linux";
				config.allowUnfree = true;
			};
			extraSpecialArgs = { inherit inputs self mypkgs; };
			modules = [ inputs.agenix.homeManagerModules.default ./users/callie/home.nix ];
		};

		nixosConfigurations = {
			deck      = mkHost "deck"      [ inputs.jovian.nixosModules.jovian ];
			sayaka    = mkHost "sayaka"    [ inputs.disko.nixosModules.disko
						         inputs.direct-vx.nixosModules.default ];
			madoka    = mkHost "madoka"    [ inputs.lanzaboote.nixosModules.lanzaboote ];
			megatron  = mkHost "megatron"  [ inputs.lanzaboote.nixosModules.lanzaboote ];
			homura    = mkHost "homura"    [ inputs.jovian.nixosModules.jovian 
							 inputs.coral.nixosModules.llm-bridge ];
			lightbulb = mkHost "lightbulb" [ ];

			reef      = mkHost "reef"      [ inputs.coral.nixosModules.default ];

			clockwork = inputs.nixos-raspberrypi.lib.nixosSystem {
				# Keep the NixOS module/package environment aligned with every
				# other host. The Raspberry Pi modules select their kernel from
				# inputs.nixos-raspberrypi.packages, which remains pinned to the
				# nixos-uconsole 25.11 package set and therefore hits its cache.
				nixpkgs = nixpkgs;
				trustCaches = true;
				specialArgs = {
					inherit inputs self;
					clib = import ./lib nixpkgs.lib;
					isCM4 = true;
				};
				modules = [
					inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.base
					inputs.nixos-raspberrypi.nixosModules.raspberry-pi-4.bluetooth
					inputs.nixos-uconsole.nixosModules.kernel
					inputs.nixos-uconsole.nixosModules.configtxt
					inputs.nixos-uconsole.nixosModules.cm
					inputs.nixos-uconsole.nixosModules.base
					inputs.nixos-uconsole.nixosModules.uc-sleep
					inputs.nixos-uconsole.nixosModules.uc-4g
					({ lib, modulesPath, ... }: {
						disabledModules = [ (modulesPath + "/rename.nix") ];
						imports = [
							(lib.mkAliasOptionModule
								[ "environment" "checkConfigurationOptions" ]
								[ "_module" "check" ])
						];
						# Preserve the 25.11 platform field consumed by the
						# pinned Raspberry Pi bootloader module.
						nixpkgs.hostPlatform = lib.mkForce {
							system = "aarch64-linux";
							"linux-kernel".target = "Image";
						};
						boot.loader.raspberry-pi.bootloader = "kernel";
						# 26.05's device-tree module asks kernels whether they
						# build DTBs. The cached 25.11 kernel predates that
						# passthru attribute but does ship the DTBs.
						hardware.deviceTree.enable = true;
						fileSystems."/" = lib.mkDefault {
							device = "/dev/disk/by-label/NIXOS_SD";
							fsType = "ext4";
						};
						fileSystems."/boot/firmware" = {
							device = lib.mkDefault "/dev/disk/by-label/FIRMWARE";
							fsType = lib.mkDefault "vfat";
							options = lib.mkForce [ "fmask=0022" "dmask=0022" ];
						};
					})
					./hosts/clockwork
					inputs.agenix.nixosModules.default
				];
			};
		};
	}

	// flake-utils.lib.eachDefaultSystem(system: let 
		pkgs = import nixpkgs { inherit system; };
	in {
		devShells.default = pkgs.mkShell {
			packages = with pkgs; [
				inputs.agenix.packages.${system}.default
			];
		};
	});
}
