# Fork-only: the machine is administered over SSH, so the install user gets the
# keys in ssh-authorized-keys, sshd stays enabled, and SSH password logins are
# switched off once a key is in place. firewall.sh opens port 22 for it.
keys_file="$OMARCHY_INSTALL/config/ssh-authorized-keys"

if [[ -n ${OMARCHY_INSTALL_USER:-} && -s $keys_file ]]; then
  home=$(getent passwd "$OMARCHY_INSTALL_USER" | cut -d: -f6)
  group=$(id -gn "$OMARCHY_INSTALL_USER")
  authorized_keys="$home/.ssh/authorized_keys"

  install -d -m 700 -o "$OMARCHY_INSTALL_USER" -g "$group" "$home/.ssh"
  [[ -f $authorized_keys ]] || install -m 600 -o "$OMARCHY_INSTALL_USER" -g "$group" /dev/null "$authorized_keys"

  while IFS= read -r key; do
    [[ -z $key || $key == \#* ]] && continue
    grep -qxF "$key" "$authorized_keys" || echo "$key" >>"$authorized_keys"
  done <"$keys_file"

  pacman -S --needed --noconfirm openssh
  systemctl enable sshd.service

  install -Dm644 /dev/stdin /etc/ssh/sshd_config.d/10-omarchy-hardening.conf <<'CONF'
# Written by the install once an SSH key was authorized.
# Delete this file and reload sshd to allow password logins again.
PasswordAuthentication no
KbdInteractiveAuthentication no
CONF
  sshd -t || rm -f /etc/ssh/sshd_config.d/10-omarchy-hardening.conf
fi
