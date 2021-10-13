{ pkgs ? null
, closurecompiler ? pkgs.closurecompiler
, zopfli ? pkgs.zopfli
, useZopfli ? true
, preserveHTML ? false
, allJsPath ? "/bin/*/all.js"
}:
input:
pkgs.runCommand "${input.name}-optimized"
{ } ''
  shopt -s globstar
  mkdir $out

  cp ${if preserveHTML then "${input}/bin/*/index.html" else ./index.html} $out/index.html

  cp -afv ${input}/* $out

  chmod +w -R $out

  rm $out${allJsPath} $out${input}${allJsPath}.externs $out/all.js $out/all.js.externs || true

  ${closurecompiler}/bin/closure-compiler --compilation_level ADVANCED --jscomp_off=checkVars --warning_level QUIET --js ${input}${allJsPath} --externs ${input}${allJsPath}.externs --js_output_file $out/all.js

  ${ if useZopfli then "${zopfli}/bin/zopfli $out/**/*.{js,css,json,html}" else "" }
''
