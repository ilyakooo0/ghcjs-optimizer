{ pkgs ? null
, closurecompiler ? pkgs.closurecompiler
, zopfli ? pkgs.zopfli
, fileExtentionsToZopfli ? [ "js" "css" "json" "html" ]
, jsToOptimize ? [ ]
, filesToCopy ? { "" = "*"; }
, copyInsteadOfOptimizeJs ? false
}:
input:
let
  flattenDirAttrSet' = prfx: x:
    with builtins;
    if isAttrs x
    then concatLists (pkgs.lib.mapAttrsToList (p: v: flattenDirAttrSet' (prfx + "/" + p) v) x)
    else [{ p = prfx; v = x; }];
  flattenDirAttrSet = name: x:
    if builtins.isAttrs x
    then (flattenDirAttrSet' "" x)
    else builtins.hrow "${name} should be an attribute set.";


  flattenFileTree = name: x: builtins.map ({ p, v }: p + "/" + v) (flattenDirAttrSet name x);

  filesToList = name: x:
    if builtins.isAttrs x
    then flattenFileTree x
    else if builtins.isList x
    then x
    else builtins.throw "${name} should be either a list or an attribute set.";
  jsToOptimizeList = flattenDirAttrSet "jsToOptimize" jsToOptimize;
in
pkgs.runCommand "${input.name}-optimized"
{ } ''

    cd ${input}
    shopt -s globstar
    mkdir $out

    chmod +w -R $out

    ${
      builtins.concatStringsSep "\n"
        (builtins.map ({p, v}: "cp -afv ${v} $out${p}")
        (flattenDirAttrSet "filesToCopy" filesToCopy ++
          pkgs.lib.optionals copyInsteadOfOptimizeJs jsToOptimizeList))
    }

    chmod +w -R $out

    ${
      pkgs.lib.optionalString (!copyInsteadOfOptimizeJs)
        (builtins.concatStringsSep "\n"
          (builtins.map ({p, v}:
            let
              i = v;
              o = p;
            in ''
            rm -f $out${o}
            ${closurecompiler}/bin/closure-compiler --compilation_level ADVANCED --jscomp_off=checkVars --warning_level QUIET --js ${input}/${i} --externs ${input}/${i}.externs --js_output_file $out${o}
            '')
          (jsToOptimizeList)))
    }

    ${
      if fileExtentionsToZopfli != []
        then "${zopfli}/bin/zopfli $out/**/*.{${builtins.concatStringsSep "\n" fileExtentionsToZopfli}}"
        else ""
    }
  ''
