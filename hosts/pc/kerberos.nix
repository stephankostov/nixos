{ pkgs, ... }:

# Kerberos for the Informatics (INF.ED.AC.UK) realm, so ssh to the jumphost and
# mlp works without password prompts. Run `kinit s2764478@INF.ED.AC.UK` once per day.
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
}
