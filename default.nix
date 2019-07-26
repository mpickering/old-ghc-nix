{ pkgs }:
let mkGhc = v@{ncursesVersion ? "6", ...}: pkgs.callPackage ./artifact.nix {} { bindistTarballs = (mkTarballs v); inherit ncursesVersion;};
    hashes = import ./hashes.nix;
    mkTarballs = { src, ...}: builtins.mapAttrs (_plat: v: pkgs.fetchurl v) src;
in
  builtins.mapAttrs (_: v: mkGhc v ) hashes // { inherit mkGhc; }
