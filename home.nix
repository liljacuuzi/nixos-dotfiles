  { config, pkgs, ... }: {
    
  
    
      home.username = "smalldog";
      home.homeDirectory = "/home/smalldog";
      home.stateVersion = "26.05";
    
      programs.bash = {
        enable = true;
        shellAliases = {
          btw = "echo i use nixos btw";
          nrs = "sudo nixos-rebuild switch";
          nrsu = "sudo nixos-rebuild switch --upgrade";
          sncgd = "sudo nix-collect-garbage -d";
          ncg = "nix-collect-garbage";
        };
      
        initExtra = ''
          export PS1='\[\e[38;5;40m\]\u\[\e[0m\] in \[\e[38;5;33m\]\w\[\e[0m\] \\$ '
        '';
      };
    
      home.packages = with pkgs; [
        bat
      ];
   
     home.file.".icewm".source = config.lib.file.mkOutOfStoreSymlink "/home/smalldog/nixos-dotfiles/icewm";
   
   
   
   
     # automatic git signing
     services.ssh-agent.enable = true;

     programs.ssh = {
       enable = true;
       # Fixes the 'enableDefaultConfig' warning
       enableDefaultConfig = false;

       # Fixes the 'matchBlocks' -> 'settings' deprecation warning
       settings = {
         "github.com" = {
           hostname = "github.com";
           user = "git";
           identityFile = "~/.ssh/id_ed25519"; 
         };
       };
     };

    programs.git = {
      enable = true;
      # Fixes 'userName', 'userEmail', and 'extraConfig' deprecation warnings
      settings = {
        user = {
          name = "liljacuuzi";
          email = "gurjotb81@gmail.com";
          signingkey = "~/.ssh/id_ed25519.pub";
        };
      gpg.format = "ssh";
      commit.gpgsign = true;
      };
    };
  }
