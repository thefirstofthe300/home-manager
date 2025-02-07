{ ... }: {
  home.file = {
    p10k = {
      target = ".p10k.zsh";
      source = ./files/p10k.zsh;
    };
  };
}
