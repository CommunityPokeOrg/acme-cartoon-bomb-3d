#!/usr/bin/env bash
# Render every printable part of the ACME cartoon bomb to binary STL.
# Requires OpenSCAD (tested with 2021.01+).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p stl

openscad --export-format binstl -o stl/bomb_body.stl  -D 'part="body"'   bomb.scad
openscad --export-format binstl -o stl/fuse_cap.stl   -D 'part="cap"'    bomb.scad
openscad --export-format binstl -o stl/track.stl      -D 'part="track"'  bomb.scad
openscad --export-format binstl -o stl/slider.stl     -D 'part="slider"' bomb.scad

# Non-printing preview of the whole assembly (fit check).
openscad --export-format binstl -o stl/assembly_preview.stl \
    -D 'part="assembly"' bomb.scad

echo "Wrote stl/*.stl"
