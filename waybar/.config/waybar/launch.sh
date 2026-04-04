#!/bin/bash

# Terminar instancias de Waybar en ejecución
killall -q waybar

# Esperar a que los procesos se cierren
while pgrep -u $UID -x waybar >/dev/null; do sleep 1; done

# Añadir un pequeño retraso para asegurar que Hyprland IPC esté listo
sleep 1

# Lanzar la barra superior
waybar -c ~/.config/waybar/modules-top.json -s ~/.config/waybar/style-top.css &

# Lanzar la barra inferior
waybar -c ~/.config/waybar/modules-bottom.json -s ~/.config/waybar/style-bottom.css &

echo "Barras superior e inferior lanzadas."
