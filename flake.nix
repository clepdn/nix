{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		jovian = {
			url = "github:Jovian-Experiments/Jovian-NixOS";
		};
		zen-browser = {
			url = "github:0xc000022070/zen-browser-flake";
			inputs = {
				# IMPORTANT: we're using "libgbm" and is only available in unstable so ensure
				# to have it up-to-date or simply don't specify the nixpkgs input
				nixpkgs.follows = "nixpkgs";
				# enable if we start using home manager
				#home-manager.follows = "home-manager"; 
			};
		};
		lanzaboote = {
			url = "github:nix-community/lanzaboote/v1.0.0";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		apple-color-emoji = {
		      url = "github:samuelngs/apple-emoji-linux";
		      inputs.nixpkgs.follows = "nixpkgs";  
		};
		agenix = {
			url = "github:ryantm/agenix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = 
	{ self, 
	  nixpkgs, 
	  zen-browser, 
	  lanzaboote,
	  apple-color-emoji,
	  jovian,
	  agenix,
	  ... 
	} @ inputs: {
		nixosConfigurations.deck = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				./hosts/deck
				jovian.nixosModules.jovian
			];
		};
		nixosConfigurations.xps = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs; };
			modules = [
				./hosts/xps
				lanzaboote.nixosModules.lanzaboote
			];
		};
		nixosConfigurations.homura-v = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs; };
			modules = [
				./hosts/homura-v
				agenix.nixosModules.default
			];
		};
		devShells.aarch64-linux.default = pkgs.mkShell {
			packages = [
				agenix.packages.aarch64-linux.default
			];
		};
	};
}
