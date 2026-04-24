lib:
lib.makeExtensible (self: {
  importFolder =
    dir:
    let
      files = builtins.readDir dir;
      fileNames = builtins.attrNames files;
      filesToImport = builtins.map (name: dir + "/${name}") (
        builtins.filter (name:
          ((builtins.match ".*.nix" name != null) && (name != "default.nix"))
          || (files.${name} == "directory")
        ) fileNames
      );
    in
    filesToImport;
})
