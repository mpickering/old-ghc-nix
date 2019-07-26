{ pkgs ? import <nixpkgs> {} }:
with builtins;
let versions = fromJSON (readFile ./versions.json);
in let urls = concatMap ({ version, bindists, ... }: map (bindist: "https://haskell.org/ghc/dist/${version}/ghc-${version}-x86_64-${bindist}.tar.xz") bindists) versions;
in with pkgs.stdenv.lib; pkgs.writeShellScriptBin "gen-hashes" ''
export PATH="${getBin pkgs.coreutils}/bin:${getBin pkgs.nix}/bin:$PATH"
echo "{"                                                                         > hashes.nix
for URL in ${concatStringsSep " " urls}; do
    SHA=$(nix-prefetch-url $URL)
    VER=$(TMP=''${URL##*/ghc-}; echo ''${TMP%%-*})
    NIXVER="ghc$(echo $VER | tr -d '.')"
    HOST=$(case ''${URL##*/} in
            *apple-darwin*) echo "x86_64-darwin";;
            *linux*) echo "x86_64-linux";;
           esac)
    NCURSES=$(case ''${URL##*/} in
                *deb8*)     echo "5";;
                *fedora27*) echo "6";;
              esac)
    echo "  \"$NIXVER\".src.$HOST = { url = \"$URL\"; sha256 = \"$SHA\"; };"     >> hashes.nix
    if [[ ! $(grep \"$NIXVER\".ncursesVersion hashes.nix) && -n $NCURSES ]]; then
        echo "  \"$NIXVER\".ncursesVersion = \"$NCURSES\";"                      >> hashes.nix
    fi
    if [[ ! $(grep \"$NIXVER\".version hashes.nix) ]]; then
        echo "  \"$NIXVER\".version = \"$VER\";"                                 >> hashes.nix
    fi
    if [[ ! $(grep \"$NIXVER\".nixversion hashes.nix) ]]; then
        echo "  \"$NIXVER\".nixversion = \"$NIXVER\";"                           >> hashes.nix
    fi
done
echo "}"                                                                         >> hashes.nix
''
