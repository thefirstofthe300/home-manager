{ pkgs, ... }: {
  programs = {
    vim = {
      enable = true;
      defaultEditor = true;
      extraConfig = ''
        set nobackup
        set nowb
        set noswapfile
        colorscheme gruvbox
        set background=dark
      '';
      plugins = with pkgs; [
        vimPlugins.gruvbox
        vimPlugins.vim-sensible
        vimPlugins.vim-terraform
      ];
    };
  };
}
