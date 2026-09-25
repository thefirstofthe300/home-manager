{ ... }:
{
  imports = [
    ./ssh.nix
    ./packages.nix
    ./terminal.nix
    ./zsh.nix
    ./files.nix
    ./vim.nix
    ./direnv.nix
    ./secrets.nix
    ./user.nix
    ../features
  ];

  manual.json.enable = false;
  manual.html.enable = false;
}
