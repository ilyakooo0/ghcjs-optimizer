{ pkgs ? null
, closurecompiler ? pkgs.closurecompiler
, zopfli ? pkgs.zopfli
, useZopfli ? true
, useClosureCompiler ? true
, createHTML ? true
, allJsPath ? "/bin/*/all.js"
}:
input:
pkgs.runCommand "${input.name}-optimized"
{ } ''
  shopt -s globstar
  mkdir $out

  ${if createHTML then "cp ${input}/bin/*/index.html $out/index.html" else ""}

  cp -afv ${input}/* $out

  chmod +w -R $out

  rm $out${allJsPath} $out${input}${allJsPath}.externs $out/all.js $out/all.js.externs || true
  
  ${
    if useClosureCompiler
      then "${closurecompiler}/bin/closure-compiler --compilation_level ADVANCED --jscomp_off=checkVars --warning_level QUIET --js ${input}${allJsPath} --externs ${input}${allJsPath}.externs --js_output_file $out/all.js"
      else ""
  }

  ${ if useZopfli then "${zopfli}/bin/zopfli $out/**/*.{js,css,json,html}" else "" }
''
