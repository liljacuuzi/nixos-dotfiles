{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (pkgs.st.overrideAttrs (_: {
      src = ../config/st;
      patches = [ ];
    }))
  ];
}
