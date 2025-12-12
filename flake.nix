{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		jovian = {
			url = "github:Jovian-Experiments/Jovian-NixOS";
		};
	};

	outputs = { self, nixpkgs, jovian }: {
		nixosConfigurations.deck = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				./configuration.nix
				jovian.nixosModules.jovian
			];
		};
	};
}
