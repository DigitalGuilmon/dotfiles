#!/bin/bash
# Cava audio visualizer output for xmobar
# Outputs a simple bar visualization using cava in raw mode

CAVA_CONFIG="/tmp/xmobar_cava.conf"

# Generate a minimal cava config for raw output
cat > "$CAVA_CONFIG" <<EOF
[general]
bars = 8
framerate = 30

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7

[smoothing]
noise_reduction = 77
EOF

# Run cava with the config, converting numbers to bar characters
cava -p "$CAVA_CONFIG" 2>/dev/null | while IFS=';' read -r -a values; do
    bars=""
    for val in "${values[@]}"; do
        case $val in
            0) bars+="▁" ;;
            1) bars+="▂" ;;
            2) bars+="▃" ;;
            3) bars+="▄" ;;
            4) bars+="▅" ;;
            5) bars+="▆" ;;
            6) bars+="▇" ;;
            7) bars+="█" ;;
            *) bars+="▁" ;;
        esac
    done
    echo "$bars"
done
