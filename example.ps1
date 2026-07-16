# =============================================================================
# Win11 Scoop安装脚本
# 用法: irm https://ghfast.top/https://raw.githubusercontent.com/svier0/scoop-ghproxy/master/example.ps1 | iex
# 功能: 安装Scoop
# =============================================================================

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

irm https://ghfast.top/https://raw.githubusercontent.com/svier0/scoop-ghproxy/master/fastinstall.ps1 | iex

scoop install main/innounp
scoop install extras/asar7z
scoop install main/ffmpeg
scoop install main/mingw

scoop install extras/windhawk
scoop install extras/rustdesk
scoop install extras/ffmpeg-batch
scoop install sysinternals/zoomit
scoop install extras/sublime-text
scoop install extras/localsend
scoop install extras/helium
# scoop install extras/neatdownloadmanager
scoop install extras/motrix-next
scoop install extras/qtscrcpy
scoop install extras/cc-switch
scoop install extras/oss-browser
scoop install extras/uniextract2
scoop install extras/potplayer
scoop install extras/qimgv-video
scoop install extras/clash-verge-rev
scoop install extras/fiddler
scoop install extras/cheat-engine
scoop install extras/64gram
scoop install extras/zed
scoop install extras/winmerge
scoop install extras/pot
scoop install extras/qq-nt
scoop install extras/wechat
scoop install extras/wecom
scoop install extras/dbx
scoop install main/python
scoop install main/bun
scoop install main/nodejs
# scoop install main/go
scoop install extras/opencode-desktop
# scoop install extras/obsidian
# scoop install main/zeroclaw
# scoop install rustup

# scoop install nonportable/sandboxie-plus-np
# scoop install nonportable/bluestacks-np

scoop install svier0/zedg
scoop install svier0/MouseInc
scoop install svier0/aardio
scoop install svier0/MusicFree
scoop install svier0/pixpin
scoop install svier0/HbuilderX
scoop install svier0/video2x
scoop install svier0/tbtool
scoop install svier0/FrpcTray
scoop install svier0/wechat_devtools
scoop install svier0/SoNovel
scoop install svier0/TomatoNovelDownloader
scoop install svier0/Hanako
scoop install svier0/NomiFun
scoop install svier0/codebase-memory-mcp


# end
