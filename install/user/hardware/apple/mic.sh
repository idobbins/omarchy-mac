# Seed absent policy and supervise the runtime graph without replacing user choices.
omarchy-hw-apple || return 0

mic_policy_dir="$HOME/.config/wireplumber/wireplumber.conf.d"
mic_policy="$mic_policy_dir/asahi-headset-mic.conf"
mkdir -p "$mic_policy_dir"
if [[ ! -e $mic_policy && ! -L $mic_policy ]]; then
  cp "$OMARCHY_PATH/default/wireplumber/wireplumber.conf.d/asahi-headset-mic.conf" "$mic_policy"
fi

mic_unit_dir="$HOME/.config/systemd/user"
mkdir -p "$mic_unit_dir"
if [[ ! -e $mic_unit_dir/omarchy-asahi-mic.service && ! -L $mic_unit_dir/omarchy-asahi-mic.service ]]; then
  cp "$OMARCHY_PATH/default/systemd/user/omarchy-asahi-mic.service" "$mic_unit_dir/"
fi
# Persist the WantedBy link without contacting a user manager during offline
# provisioning. Existing user unit overrides and enablement links are preserved.
mic_wants="$mic_unit_dir/graphical-session.target.wants"
mkdir -p "$mic_wants"
if [[ ! -e $mic_wants/omarchy-asahi-mic.service && ! -L $mic_wants/omarchy-asahi-mic.service ]]; then
  ln -s ../omarchy-asahi-mic.service "$mic_wants/omarchy-asahi-mic.service"
fi
mic_status=0
omarchy-audio-asahi-mic-map || mic_status=$?
# The bus can be live while XDG_RUNTIME_DIR is unset -- the guided install runs
# this from sudo -i while the owner has an ssh session open -- and systemctl
# --user finds the bus only through that variable.
runtime_dir=${XDG_RUNTIME_DIR:-/run/user/$UID}
if [[ -S $runtime_dir/bus ]]; then
  XDG_RUNTIME_DIR=$runtime_dir systemctl --user daemon-reload
  XDG_RUNTIME_DIR=$runtime_dir systemctl --user start omarchy-asahi-mic.service
fi
if (( mic_status != 0 && mic_status != 75 )); then
  return "$mic_status"
fi
