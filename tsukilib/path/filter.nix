lib:

let

  inherit ( builtins )
    isPath
    isString
    match
    ;

  inherit ( lib )
    escapeRegex
    ;

  regexFor =
    extension: ".*${escapeRegex extension}$";

in

{

  # hasExtension :: string -> path -> bool
  #
  # Check if $path ends with with $extension,
  # whether it's directory or file does not matter.
  #
  hasExtension =
    extension: path:
      assert isString extension;
      assert isPath path;
      if ( match (regexFor extension) (toString path) ) != null
      then true
      else false;

}
