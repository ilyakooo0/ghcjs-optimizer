{ pkgs ? null
, closurecompiler ? pkgs.closurecompiler
, zopfli ? pkgs.zopfli
, useZopfli ? true
, preserveHTML ? false
}:
input:
pkgs.runCommand "${input.name}-optimized"
{ } ''
  shopt -s globstar
  mkdir $out

  cp ${if preserveHTML then "${input}/bin/*/index.html" else ./index.html} $out/index.html

  chmod +w -R $out

  ${closurecompiler}/bin/closure-compiler --compilation_level ADVANCED --jscomp_off=checkVars --warning_level QUIET --js ${input}/bin/*/all.js --externs ${input}/bin/*/all.js.externs --js_output_file $out/all.js

  ${ if useZopfli then "${zopfli}/bin/zopfli $out/**/*.{js,css,json,html}" else "" }
''
