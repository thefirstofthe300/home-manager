{ ... }:
{
  imports = [ ../profiles/personal.nix ];

  features.development.enable = true;

  dconf = {
    settings = {
      "org/gnome/desktop/interface" = {
        gtk-theme = "Adwaita-dark";
        icon-theme = "Adwaita";
        cursor-theme = "Adwaita";
        font-name = "Noto Sans 11";
        document-font-name = "Noto Serif 11";
        monospace-font-name = "FiraCode Nerd Font Mono 10";
      };
    };
  };

  services.flatpak = {
    enable = true;
    packages = [
      "com.spotify.Client"
      "com.github.tchx84.Flatseal"
      "net.nokyan.Resources"
    ];
  };
}
