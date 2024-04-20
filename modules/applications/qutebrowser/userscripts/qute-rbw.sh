#!/usr/bin/env bash

rbw unlocked > /dev/null 2>&1

if [[ "$?" -eq 1 ]]; then
    kitty -T "rbw password prompt" rbw unlock > /dev/null 2>&1 && hyprctl dispatch focuswindow title:qutebrowser && rofi-rbw
else
    rofi-rbw
fi
