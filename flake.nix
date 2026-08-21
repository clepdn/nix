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
		home-manager-clockwork = {
			url = "github:nix-community/home-manager/release-25.11";
			inputs.nixpkgs.follows = "nixos-uconsole/nixpkgs";
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
		nano = {
			url = "git+https://tangled.org/did:plc:vsjfqg3m57r3xghg4pqv4v6i";
			inputs = {
				nixpkgs.follows = "nixpkgs";
				flake-utils.follows = "flake-utils";
			};
		};
		llm-bridge = {
			url = "git+ssh://git@knot.bas.sh/did:plc:qnt6tjqrplzxukueirbxqmya";
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
			url = "git+ssh://git@codeberg.org/cowie/md-site.git?ref=first-class-events";
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
		paseo = {
			url = "github:getpaseo/paseo/v0.4.0";
		};
		omp = {
			url = "git+https://github.com/metaphorics/oh-my-pi?ref=feat/cross-platform-sleep-prevention";
			inputs.nixpkgs.follows = "nixpkgs";
		};

	};

	outputs =
	inputs @ { self, nixpkgs, flake-utils, home-manager, ... }:

	let
		mypkgs = import ./pkgs { pkgs = nixpkgs.legacyPackages.x86_64-linux; lib = nixpkgs.lib; };
		armPkgs = import nixpkgs {
			system = "aarch64-linux";
			config.allowUnfree = true;
		};
		armMypkgs = import ./pkgs { pkgs = armPkgs; lib = nixpkgs.lib; };
		clockworkUserModule = { ... }: {
			imports = [
				(import ./users/callie/graphicalSession.nix {
					pkgs = armPkgs;
					inputs = inputs;
					mypkgs = armMypkgs;
				})
			];
			home-manager.useGlobalPkgs = true;
			home-manager.extraSpecialArgs = {
				inherit inputs;
				mypkgs = armMypkgs;
			};
			home-manager.sharedModules = [
				inputs.agenix.homeManagerModules.default
			];
		};
		clockworkModules = [
			./hosts/clockwork
			inputs.agenix.nixosModules.default
			inputs.home-manager-clockwork.nixosModules.home-manager
			clockworkUserModule
		];
		mkHost = host: extraModules: nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = {
				inherit inputs self mypkgs;
				agenixPackage = inputs.agenix.packages.x86_64-linux.default;
				clib = import ./lib nixpkgs.lib;
			};
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

		checks.x86_64-linux.codex-remote-control =
			import ./checks/codex-remote-control.nix {
				pkgs = nixpkgs.legacyPackages.x86_64-linux;
			};

		nixosConfigurations = {
			deck      = mkHost "deck"      [ inputs.jovian.nixosModules.jovian ];
			sayaka    = mkHost "sayaka"    [ inputs.disko.nixosModules.disko
						         inputs.direct-vx.nixosModules.default ];
			madoka    = mkHost "madoka"    [ inputs.lanzaboote.nixosModules.lanzaboote inputs.paseo.nixosModules.default ];
			megatron  = mkHost "megatron"  [ inputs.lanzaboote.nixosModules.lanzaboote inputs.paseo.nixosModules.default ];
			homura    = mkHost "homura"    [ inputs.jovian.nixosModules.jovian 
							 inputs.llm-bridge.nixosModules.llm-bridge
							 inputs.nano.nixosModules.default
							 inputs.paseo.nixosModules.default ];
			lightbulb = mkHost "lightbulb" [ ];

			reef      = mkHost "reef"      [ inputs.nano.nixosModules.nano-executor ];

			clockwork = inputs.nixos-uconsole.lib.mkUConsoleSystem {
				variant = "cm4";
				specialArgs = {
					inherit inputs self;
					mypkgs = armMypkgs;
					agenixPackage = inputs.agenix.packages.aarch64-linux.default;
					clib = import ./lib inputs.nixos-uconsole.inputs.nixpkgs.lib;
					pkgsUnstable = armPkgs;
				};
				modules = clockworkModules;
			};
		};

		packages.aarch64-linux.clockwork-image =
			(inputs.nixos-uconsole.lib.mkUConsoleImage {
				variant = "cm4";
				modules = [
					({ ... }: {
						_module.args = {
							inherit self inputs;
							mypkgs = armMypkgs;
							agenixPackage = inputs.agenix.packages.aarch64-linux.default;
							pkgsUnstable = armPkgs;
						};
					})
				] ++ clockworkModules;
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
