# Install

## One-shot install

Run this in the current directory:

```bash
./install.sh
```

The script opens a selection menu. You can choose:

- install and configure the `swayfx` + `waybar` desktop
- update configs only without installing packages
- run the `fcitx5` customizer
- run both in sequence
- run the `fcitx5` recommended preset

It also supports non-interactive modes:

```bash
./install.sh sway
./install.sh config
./install.sh fcitx
./install.sh fcitx-recommend
./install.sh all
./install.sh all-recommend
```

For the `fcitx5` part, the script downloads and runs the online customizer you specified. These are the equivalent upstream commands:

```bash
bash fcitx5_customizer.sh
bash fcitx5_customizer.sh recommend
bash -c "$(curl -fsSL https://fcitx5.debuggerx.com/fcitx5_customizer.sh)"
curl -sSL https://fcitx5.debuggerx.com/fcitx5_customizer.sh | bash -s -- recommend
```

For the `swayfx` + `waybar` part, the script uses `yay` to install:

```bash
yay -S --needed swayfx kitty waybar wlogout blueman bluez-utils networkmanager nm-connection-editor pavucontrol thunar tumbler thunar-archive-plugin file-roller gvfs libnotify grim slurp wl-clipboard polkit-gnome otf-font-awesome noto-fonts-cjk fuzzel mako swaylock swayidle swaybg network-manager-applet cliphist swappy playerctl brightnessctl fzf pacman-contrib otf-commit-mono-nerd upower
```

The package set is:

- `swayfx`
- `kitty`
- `waybar`
- `wlogout`
- `blueman`
- `bluez-utils`
- `networkmanager`
- `nm-connection-editor`
- `pavucontrol`
- `thunar`
- `tumbler`
- `thunar-archive-plugin`
- `file-roller`
- `gvfs`
- `libnotify`
- `grim`
- `slurp`
- `wl-clipboard`
- `polkit-gnome`
- `otf-font-awesome`
- `noto-fonts-cjk`
- `fuzzel`
- `mako`
- `swaylock`
- `swayidle`
- `swaybg`
- `network-manager-applet`
- `cliphist`
- `swappy`
- `playerctl`
- `brightnessctl`
- `fzf`
- `pacman-contrib`
- `otf-commit-mono-nerd`
- `upower`

It deploys the configs from this repo into `~/.config` and directly replaces any existing `sway`, `waybar`, `mako`, `fuzzel`, `swaylock`, or `kitty` directories. It also removes an existing `~/.config/quickshell` directory during deploy so the old bar does not get restarted by mistake.

## Manual deploy

If you only want to copy the configs without installing packages:

```bash
mkdir -p ~/.config
rm -rf ~/.config/quickshell
cp -r .config/sway .config/waybar .config/mako .config/fuzzel .config/swaylock .config/kitty ~/.config/
```

Then log into `sway` again, or reload the config inside sway:

```bash
swaymsg reload
```

If the bar does not appear after reload, start it manually once:

```bash
~/.config/waybar/scripts/restart-waybar
```

To fetch and switch to the current DailyBing wallpaper inside sway, use:

```bash
~/.config/sway/scripts/update-bing-wallpaper
```
