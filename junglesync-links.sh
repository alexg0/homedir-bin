#!/bin/bash
##
## junglesync-links.sh
## 
## Made by Alexander Goldstein
## Login   <alexg@alexland.org>
## 
## Started on  Mon Nov 30 17:45:47 2009 Alexander Goldstein
##
## Create appropreate links if don't exist for to junglesync/dropbox folder

## === config ===
TARGET_DIR="$HOME/junglesync"
SRC_PREFIX="$HOME"

die() { echo $*; exit 128; }

link_and_move() {
  what=$1
  short_what="${what##$SRC_PREFIX}"
  target="${TARGET_DIR}${short_what}"
  echo "what=$short_what target=$target"

#  echo press C-c; read

  if [[ -h "$what" ]]; then
    if [[ $(readlink "$what") == "$target" ]]; then
      echo ".. $short_what already points at $target"
    else
      die "$0: link '$short_what' exists, not pointed at '$target', remove & rerun"
    fi
  elif [[ -f "$what" || -d "$what" ]]; then
    if [[  -f "$target" || -d "$target" ]]; then
       die "both $short_what and $target already exists, and not links. manual intervention required"  
    else
      (( $move_ok )) || die "$0: --move flag requred to move $short_what"

      mkdir -p $(dirname "$target") && \ 
        mv "$what" "$target" && \ 
        ln -s "$target" "$what" || \
        die "failed to move $short_what to $target and link"
    fi
  elif [[ -f "$target" || -d "$target" ]]; then
    ln -s "$target" "$what" || \
      die "failed to link $short_what to $target"
  fi

}

move_ok=0
[[ "$1" == '--move' || "$1" == '-m' ]] && { move_ok=1; shift; }
[[ -z "$1" ]] || die "usage: $0 [-m|--move]"


link_and_move ~/.purple/logs
link_and_move ~/src


