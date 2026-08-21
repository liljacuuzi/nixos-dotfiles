{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (st.overrideAttrs (old: {
      src = ../config/st;                 # your local tree

      buildInputs = old.buildInputs ++ [ harfbuzz ];

      # Optional but often useful: force a clean config.def.h from your tree
      # postPatch = (old.postPatch or "") + ''
      #   cp ${../config/st}/config.h config.def.h
      # '';
    }))
  ];
}
