# Kerberos keytab (`krb5.keytab`)

`krb5.keytab` is the sops-encrypted keytab for `s2764478@INF.ED.AC.UK`. The
`kinit-refresh` service (`hosts/pc/kerberos.nix`) uses it to renew the Kerberos
ticket every 4 hours, so `ssh mlp` works without running `kinit` by hand.

The keytab stops working when the university password changes. Regenerate it
then, or whenever `systemctl status kinit-refresh` shows kinit failing on
authentication (e.g. `Preauthentication failed`).

## Regenerating it

The university VPN must be up (`sudo systemctl start openvpn-uni`): the `-f`
flag fetches the salt from the KDC.

```bash
# 1. make the keytab (asks for your password)
ktutil
  addent -password -p s2764478@INF.ED.AC.UK -k 1 -e aes256-cts-hmac-sha1-96 -f
  wkt /tmp/krb5.keytab
  quit

# 2. encrypt it with the age key the other secrets use, then delete the plaintext
cd ~/nixos
nix shell nixpkgs#sops -c sops -e --age age1xupmve3yly8zp7jmfnn29kyuqwp37n856mx5u8danljttf9csfwq05ea6k \
  --input-type binary --output-type binary /tmp/krb5.keytab > secrets/krb5.keytab
shred -u /tmp/krb5.keytab

# 3. rebuild so sops-nix decrypts the new file, then check it works
sudo nixos-rebuild switch --flake ~/nixos
sudo systemctl start kinit-refresh && klist
```
