# mpv-export-clip

a mpv lua script to cut clips from video

## How to use

```sh
mkdir -p ~/.config/mpv/scripts
wget https://raw.githubusercontent.com/citrus-lemon/mpv-export-clip/master/export_clip.lua -O ~/.config/mpv/scripts/export_clip.lua
```

and register function

add this to `~/.config/mpv/input.conf`

```
# mpv-export-clip/export_clip.lua
a          script-message set-ab-loop-a
b          script-message set-ab-loop-b
Ctrl+a     script-message seek-ab-loop-a
Ctrl+b     script-message seek-ab-loop-b
e          script-message export-loop-clip

# add following for moving pointer faster
Alt+RIGHT  frame-step
Alt+LEFT   frame-back-step
```

clip will be saved in `screenshot-directory` folder

## Roadmap

- [x] generate video clip from ab-loop
- [ ] record clip time info into a file and able to recover
- [ ] build an interface for browsing clips and useful operations
