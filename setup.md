This is a setup guide to remind myself what wont be automatically setup.

1. Github signing

Im doing authentication for nixos-dotfiles with an ssh file I upload to my github account, so run:
ssh-keygen -t ed25519 -C "your_email@example.com"
to create the key and check ~/.ssh/config

2. Switching between a screensaver and image background for lockscreen

To change between the two, you have to go into ~/nixos-dotfiles/configuration.nix and near the top you will have to comment out onne option to have the other option function, its described in more detail in configuration.nix 

3. Drivers

Switching from my current amd setup to a potentially nvidia setup will require me to edit a few lines in configuration.nix to change a few lines for hardware.graphicss {}.
