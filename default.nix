{ pkgs }:
let mkGhc = pkgs.callPackage ./artifact.nix {};
    hashes = builtins.fromJSON (builtins.readFile ./hashes.json);
    mkTarball = { url, hash, ...}: pkgs.fetchurl { url = url;
                                                       sha256 = hash;
                                                     };
in
  builtins.mapAttrs (_: v: mkGhc { bindistTarball = (mkTarball v); ncursesVersion = "6";}) hashes // { inherit mkGhc; }
