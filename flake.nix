{
  description = "Discord Dynamic Channel bot";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        dynamic-channels-bot = pkgs.python3Packages.buildPythonApplication {
          pname = "dynamic-channels-bot";
          version = "1.0.0";
          
          src = ./.;

          build-system = [ pkgs.python3Packages.setuptools ];

          pyproject = true;
          
          propagatedBuildInputs = with pkgs.python3Packages; [
            disnake
            psutil
          ];
        };

      in {
        packages.default = dynamic-channels-bot;
        packages.dynamic-channels-bot = dynamic-channels-bot;

      }
    ) // {
      # NixOS module
      nixosModules.default = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.services.dynamic-channels-bot;
        in {
          options.services.dynamic-channels-bot = {
            enable = mkEnableOption "Discord bot service";
            
            tokenFile = mkOption {
              type = types.path;
              description = "Path to file containing the Discord bot token";
              example = "/run/secrets/discord-token";
            };
          };

          config = mkIf cfg.enable {
            # SystemD service
            systemd.services.dynamic-channel-bot = {
              description = "Dynamic Channel Bot Service";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];
              
              serviceConfig = {
                Type = "simple";
                Restart = "always";
                RestartSec = "10";

                ExecStart = "${self.packages.${pkgs.system}.discordBot}/bin/dynamic-channel-bot";
                
                # Dynamic user management
                DynamicUser = true;
                StateDirectory = "dynamic-channel-bot";
                WorkingDirectory = "%S/dynamic-channel-bot";  # %S = /var/lib
                
                # Security settings
                NoNewPrivileges = true;
                PrivateTmp = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                
                # Load token from file
                EnvironmentFile = cfg.tokenFile;
              };
            };
          };
        };
    };
}