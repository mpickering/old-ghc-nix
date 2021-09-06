{ pkgs ? import <nixpkgs> {} }:
with builtins;
let versions = fromJSON (readFile ./versions.json);
in let urls = concatMap ({ version, bindists, ... }: map (bindist: "https://haskell.org/ghc/dist/${version}/ghc-${version}-${bindist}.tar.xz") bindists) versions;
in with pkgs.lib; pkgs.writeShellScriptBin "gen-hashes" ''
export PATH="${getBin pkgs.coreutils}/bin:${getBin pkgs.nix}/bin:$PATH"
echo "{"                                                                         > hashes.nix
for URL in ${concatStringsSep " " urls}; do
    SHA=$(nix-prefetch-url $URL)
    VER=$(TMP=''${URL##*/ghc-}; echo ''${TMP%%-*})
    NIXVER="ghc$(echo $VER | tr -d '.')"
    HOST=$(case ''${URL##*/} in
            *x86_64-apple-darwin*) echo "x86_64-darwin";;
            *x86_64-*linux*) echo "x86_64-linux";;
            *aarch64-*linux*) echo "aarch64-linux";;
           esac)
    NCURSES=$(case ''${URL##*/} in
                *deb8*)     echo "5";;
                *deb9*)     echo "5";;
                *fedora27*) echo "6";;
              esac)
    echo "  \"$NIXVER\".hosts.$HOST.src = { url = \"$URL\"; sha256 = \"$SHA\"; };"     >> hashes.nix
    if [[ ! $(grep \"$NIXVER\".hosts.$HOST.ncursesVersion hashes.nix) && -n $NCURSES ]]; then
        echo "  \"$NIXVER\".hosts.$HOST.ncursesVersion = \"$NCURSES\";"                      >> hashes.nix
    fi
    if [[ ! $(grep \"$NIXVER\".version hashes.nix) ]]; then
        echo "  \"$NIXVER\".version = \"$VER\";"                                 >> hashes.nix
    fi
    if [[ ! $(grep \"$NIXVER\".nixversion hashes.nix) ]]; then
        echo "  \"$NIXVER\".nixversion = \"$NIXVER\";"                           >> hashes.nix
    fi
    if [[ ! $(grep \"$NIXVER\".bindistVersion hashes.nix) ]]; then
        echo "  \"$NIXVER\".bindistVersion = \"$VER\";"                          >> hashes.nix
    fi
done
echo "}"                                                                         >> hashes.nix
''
