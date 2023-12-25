## Review
- drop shebang
- look for variable definitions (zsh/fish not compat)
  - also functions and for loops => not compat
- cleanup / format entire file
- aliases use single quotes unless " needed (nice to have)
- don't use ${foo} in string interpolation => use $foo only
- cannot expand abbreviations so if they are used in another abbreviation/alias that won't work
  - look into `rr` alias in `files.zsh` (`fish_compat`)