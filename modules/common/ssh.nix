{ ... }:
{
  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*" = {
        identityAgent = "~/.1password/agent.sock";
      };
    };
  };
}
