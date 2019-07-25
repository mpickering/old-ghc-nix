{ pkgs ? (import <nixpkgs> {}) }:
let mkGhc = v@{ncursesVersion ? "6", ...}: pkgs.callPackage ./artifact.nix {} { bindistTarballs = (mkTarballs v); inherit ncursesVersion;};
    hashes = import ./hashes.nix;
    mkTarball = { url, hash, ...}: pkgs.fetchurl { url = url;
                                                       sha256 = hash;
                                                     };
in
  builtins.mapAttrs (_: v: mkGhc v ) hashes // { inherit mkGhc; }
