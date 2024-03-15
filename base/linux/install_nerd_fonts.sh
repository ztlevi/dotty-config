#!/usr/bin/env zsh
# Install nerd fonts for Linux
mkdir -p $XDG_DATA_HOME/fonts/
local nerd_fonts_version="v3.1.1"
(
  cd $XDG_DATA_HOME/fonts/
  # Firacode
  font_types=("Regular" "Medium" "Bold" "Light")
  for font_type in ${font_types[@]}; do
    curl -fLo "FiraCodeNerdFont-$font_type.ttf" \
      https://github.com/ryanoasis/nerd-fonts/raw/$nerd_fonts_version/patched-fonts/FiraCode/$font_type/FiraCodeNerdFont-$font_type.ttf
    curl -fLo "FiraCodeNerdFontMono-$font_type.ttf" \
      https://github.com/ryanoasis/nerd-fonts/raw/$nerd_fonts_version/patched-fonts/FiraCode/$font_type/FiraCodeNerdFontMono-$font_type.ttf
  done
  # UbuntuMono
  font_types=("Regular" "Bold")
  for font_type in ${font_types[@]}; do
    curl -fLo "UbuntuMonoNerdFontMono-$font_type.ttf" \
      https://github.com/ryanoasis/nerd-fonts/raw/$nerd_fonts_version/patched-fonts/UbuntuMono/$font_type/UbuntuMonoNerdFontMono-$font_type.ttf
  done
)
fc-cache -f -v
