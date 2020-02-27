{ pkgs ? (import <nixpkgs> {}) }:
let mkGhc = key: v@{ncursesVersion ? "6", ...}:
      pkgs.callPackage ./artifact.nix {} {
        bindistTarballs = (mkTarballs v);
        bindistVersion = v.bindistVersion or null;
        inherit ncursesVersion key;
      };
    hashes = import ./hashes.nix;
    mkTarball = { url, hash, ...}: pkgs.fetchurl { url = url;
                                                       sha256 = hash;
                                                     };
in
  builtins.mapAttrs (key: v: mkGhc key v ) hashes // { inherit mkGhc; }
