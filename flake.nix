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

			clockwork = inputs.nixos-uconsole.lib.mkUConsoleSystem {
				variant = "cm4";
				specialArgs = {
					inherit inputs self;
					clib = import ./lib inputs.nixos-uconsole.inputs.nixpkgs.lib;
					pkgsUnstable = nixpkgs.legacyPackages.aarch64-linux;
				};
				modules = [
					./hosts/clockwork
					inputs.agenix.nixosModules.default
				];
			};
		};

		packages.aarch64-linux.clockwork-image =
			(inputs.nixos-uconsole.lib.mkUConsoleImage {
				variant = "cm4";
				modules = [
					({ ... }: {
						_module.args = {
							inherit self;
							agenixPackage = inputs.agenix.packages.aarch64-linux.default;
							pkgsUnstable = nixpkgs.legacyPackages.aarch64-linux;
						};
					})
					./hosts/clockwork
					inputs.agenix.nixosModules.default
				];
			}).config.system.build.sdImage;
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
