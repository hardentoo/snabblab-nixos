{ config, pkgs, lib, ... }:
with lib;
with pkgs;

let
  snabb_bot = writeScript "snabb_bot.sh" (readFile (fetchurl {
     url = "https://raw.githubusercontent.com/eugeneia/snabb/8ae18fa620a81a45731772ba3a551d768e39cd17/src/scripts/snabb_bot.sh";
     sha256 = "fb94d8697ce9fddc0d5f1c1a7f2c5aec1ccc56559028aa4e1baae387d64baf29";
  }));
in {
  options = {

    services.snabb_bot = {

      credentials = lib.mkOption {
        type = types.str;
        default = "";
        description = ''
          GitHub credentials for SnabbBot instance.
        '';
        example = ''
          username:password
        '';
      };

      repo = lib.mkOption {
        type = types.str;
        default = "SnabbCo/snabb";
        description = ''
          Target GitHub repository for SnabbBot instance.
        '';
      };

      dir = lib.mkOption {
        type = types.str;
        default = "/tmp/snabb_bot";
        description = ''
          Target GitHub repository for SnabbBot instance.
        '';
      };

      current = lib.mkOption {
        type = types.str;
        default = "master";
        description = ''
          The branch to merge pull requests with.
        '';
      };

      period = lib.mkOption {
        type = types.str;
        default = "* * * * *";
        description = ''
          This option defines (in the format used by cron) when the
          SnabbBot runs. The default is every minute.
        '';
      };

      environment = lib.mkOption {
        type = types.str;
        default = "";
        description = ''
          This option defines (in shell format, e.g.: `export FOO=bar; ...')
          which additional environment variables will be set when
          SnabbBot runs.
          ''; };

    };

  };

  config = {

    systemd.services.snabb_bot =
      { description = "Run SnabbBot";
        path  = [ bash curl git docker jq pciutils busybox ];
        script =
          ''
            export GITHUB_CREDENTIALS=${config.services.snabb_bot.credentials}
            export REPO=${config.services.snabb_bot.repo}
            export SNABBBOTDIR=${config.services.snabb_bot.dir}
            export CURRENT=${config.services.snabb_bot.current}

            ${config.services.snabb_bot.environment}

            exec flock -x -n /var/lock/snabb_bot ${snabb_bot}
          '';
        environment.SSL_CERT_FILE = config.environment.sessionVariables.SSL_CERT_FILE;
      };

    services.cron.systemCronJobs =
      [ "${config.services.snabb_bot.period} root ${config.systemd.package}/bin/systemctl start snabb_bot.service" ];

  };
}
