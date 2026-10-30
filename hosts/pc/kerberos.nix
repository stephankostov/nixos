{ config, pkgs, ... }:

# Kerberos for the Informatics (INF.ED.AC.UK) realm, so ssh to the jumphost and
# mlp works without password prompts. The ticket is refreshed from a keytab (sops secret
# krb5_keytab) by the kinit-refresh timer below; `systemctl start kinit-refresh` to force it.
{
  security.krb5 = {
    enable = true;
    settings.libdefaults = {
      default_realm = "INF.ED.AC.UK";
      # KDCs are found via DNS SRV records (_kerberos._udp.inf.ed.ac.uk).
      dns_lookup_kdc = true;
      # needed so GSSAPIDelegateCredentials can forward the ticket.
      forwardable = true;
    };
  };

  # the default nixpkgs openssh is built without Kerberos, so GSSAPI options would be ignored.
  programs.ssh.package = pkgs.openssh.override { withKerberos = true; };

  # keeps steph's ticket cache fresh. retries every 5 min on failure (e.g. no network yet).
  systemd.services.kinit-refresh = {
    description = "Refresh Kerberos ticket for s2764478@INF.ED.AC.UK";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "steph";
      Environment = "KRB5CCNAME=FILE:/tmp/krb5cc_1000";
      ExecStart = "${config.security.krb5.package}/bin/kinit -kt ${config.sops.secrets.krb5_keytab.path} s2764478@INF.ED.AC.UK";
      Restart = "on-failure";
      RestartSec = "5min";
    };
  };
  systemd.timers.kinit-refresh = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "4h";
    };
  };
}
