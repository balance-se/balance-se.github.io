#!/usr/bin/env bash
# Turn the club's phone snapshots into print-ready masters for the homepage.
#
#   photos/original/*.jpg   camera files, never touched, never published
#   assets/img/kozosseg/    the masters this script writes; Hugo resizes them
#                           into the responsive srcset (see layouts/partials/photo.html)
#
# Re-run after replacing anything in photos/original/. Needs ImageMagick 7.
#
# Two things happen per photo:
#
#   1. A hand-picked crop. The originals are wide-angle phone shots with a lot
#      of ceiling and empty mat around the subject; the crop rectangles below
#      were chosen by eye so each photo arrives at the exact aspect ratio its
#      slot on the page uses. That means the browser never has to guess a crop
#      with object-fit, so nobody loses a head to a breakpoint.
#   2. A shared grade — a gentle S-curve for contrast, a little saturation, a
#      touch of unsharp — plus a per-photo white-balance nudge. The gym shots
#      run cool and flat, the camp shot runs tungsten-orange; evening them out
#      is what makes five snapshots read as one set.
#
# Crop syntax is ImageMagick's: WIDTHxHEIGHT+LEFT+TOP, in source pixels
# (every original is 2048x1536).

set -euo pipefail
cd "$(dirname "$0")/.."

src="photos/original"
out="assets/img/kozosseg"
mkdir -p "$out"

# Shared look: a little extra saturation and a light unsharp. Contrast is a
# sigmoidal S-curve rather than a levels stretch, because every one of these
# frames already touches both ends of the histogram — blown windows at one end,
# black uniforms at the other — so anything that clips would eat real detail.
# Its strength is per photo: the backlit gym shots need less than the flat ones.

# name|crop|aspect|red gain|blue gain|contrast|gamma
photos=(
    # Hero. Drops the ceiling and the far-right crash mat; keeps the wall bars
    # and the window wall, which are what make the room recognisable.
    "edzes-terem|1440x960+330+400|3:2|1.00|1.00|2.6|1.06"

    # Competition. A full-length standing group in a near-square original: the
    # five of them span too much width to crop any tighter without cutting
    # somebody off the end, so this is the full frame width with the head and
    # foot margins balanced. Brightly lit hall, already the most contrasty
    # frame of the set, so it gets the gentlest curve.
    "verseny|2048x1536+0+140|4:3|1.02|0.97|2.4|1.00"

    # Kids' group. Tightened onto the line of children; the original gave two
    # thirds of the frame to ceiling and empty mat. Shot cool, warmed back up.
    # Not on the homepage at the moment — kept prepared so putting it back is a
    # one-line change in content/_index.md.
    "gyerekek|1148x861+345+305|4:3|1.03|0.96|3.4|1.00"

    # Coaches. Already well framed — only the dead wood above and floor below
    # are trimmed. The wooden wall is genuinely warm, so barely correct it.
    "edzok|1832x1374+109+80|4:3|0.99|1.02|3.0|1.00"

    # Camp evening. Shifted up and in so the table sits centred and fewer
    # foreground heads are clipped by the bottom edge. Heavy tungsten cast.
    "tabor-este|1760x1320+120+120|4:3|0.95|1.08|3.0|1.00"

    # Belt-exam group photo, the full-width band. 16:7 puts the two rows edge
    # to edge instead of stranding them above a metre of empty parquet.
    "csoportkep|1952x854+54+402|16:7|0.98|1.03|3.2|1.00"
)

for entry in "${photos[@]}"; do
    IFS='|' read -r name crop aspect r b contrast gamma <<<"$entry"
    magick "$src/$name.jpg" \
        -auto-orient \
        -crop "$crop" +repage \
        -colorspace sRGB \
        -channel R -evaluate multiply "$r" -channel B -evaluate multiply "$b" +channel \
        -gamma "$gamma" \
        -modulate 100,106,100 \
        -sigmoidal-contrast "$contrast,52%" \
        -unsharp 0x0.8+0.6+0.01 \
        -strip -quality 92 -sampling-factor 4:4:4 \
        "$out/$name.jpg"
    printf '%-14s %-16s %-5s -> %s\n' \
        "$name" "$(magick identify -format '%wx%h' "$out/$name.jpg")" "$aspect" "$out/$name.jpg"
done
