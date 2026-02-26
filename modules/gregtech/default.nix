{ config, pkgs, lib, ... }:

let 
	cfg = config.services.gregtech;
in
{
	options.services.gregtech = {
		enable = lib.mkEnableOption "Gregtech";

		dataDir = lib.mkOption {
			type = lib.types.path;
			default = "/var/lib/gregtech";
			description = "Gregtech server folder location";
		};

		stateDir = lib.mkOption {
			type = lib.types.str;
			default = "minecr";
			description = "Home directory name in /var/lib/ for the minecraft user.";
		};
		
		extraJvmOpts = lib.mkOption {
			type = lib.types.str;
			default = "";
			description = "Extra JVM arguments";
		};
	};

	config = lib.mkIf cfg.enable {
		systemd.services.gregtech = {
			description = "Gregtech server";
			wantedBy = [ "multi-user.target" ];
			after = [ "network.target" ];

			serviceConfig = {
				Type = "forking";
				User = "minecraft";
				Group = "minecraft";
				WorkingDirectory = cfg.dataDir;

				ExecStart = "${pkgs.tmux}/bin/tmux -S tmux.sock new-session -d -s minecraft '${pkgs.jdk21}/bin/java -Xmx8G -Xms512M -Dfml.readTimeout=180 @java9args.txt -javaagent:Log4jPatcher.jar -jar lwjgl3ify-forgePatches.jar nogui'";
				ExecStartPost = "${pkgs.coreutils}/bin/chmod 770 tmux.sock";
	
				ExecStop = "${pkgs.tmux}/bin/tmux -S tmux.sock kill-session -t minecraft";
				ExecStopPost = "${pkgs.coreutils}/bin/rm -f tmux.sock";

				StateDirectory = cfg.stateDir;

				TimeoutStopSec = "60s";
				Restart = "on-failure";
				RestartSec = "30s";

				StartLimitBurst = 2;
				StartLimitIntervalSec = 600;
			};
		};

		users.users.minecraft = {
			isSystemUser = true;
			group = "minecraft";
			shell = pkgs.bash;
		};

		users.groups.minecraft = {};
	};
}
