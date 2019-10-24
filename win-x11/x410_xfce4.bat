@echo off
start /B x410.exe /wm

ubuntu1804.exe run "if [ -z $(pidof xfce4-panel) ]; then export DISPLAY=127.0.0.1:0.0; cd ~; xfsettingsd --sm-client-disable; xfce4-panel --sm-client-disable --disable-wm-check; taskkill.exe /IM x410.exe; fi;"