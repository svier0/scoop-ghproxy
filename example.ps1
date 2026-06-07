# =============================================================================
# Win11 Scoop安装脚本
# 用法: irm https://ghfast.top/https://raw.githubusercontent.com/svier0/scoop-ghproxy/master/example.ps1 | iex
# 功能: 安装Scoop
# =============================================================================

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 有需要可以通过设置环境变量，来设置安装位置
# 设置主目录（应用默认装这里）
$env:SCOOP='D:\Scoop'
[Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')

Write-Host "安装scoop 并注入 scoop-ghproxy"
$ghproxy_hiddenmenu = $true
irm "https://ghfast.top/https://raw.githubusercontent.com/svier0/scoop-ghproxy/master/script.ps1" | iex
Install-Scoop

# 设置缓存目录（下载的安装包存这里）
scoop config cache_path 'D:\Scoop\cache'


scoop bucket add extras
scoop bucket add sysinternals

scoop install extras/windhawk
scoop install extras/rustdesk
scoop install main/ffmpeg
scoop install extras/ffmpeg-batch
scoop install sysinternals/zoomit
scoop install extras/qtscrcpy
scoop install extras/another-redis-desktop-manager
scoop install extras/cc-switch
scoop install extras/localsend
scoop install extras/oss-browser
scoop install extras/uniextract2
scoop install extras/sublime-text
scoop install extras/potplayer
scoop install extras/helium
scoop install extras/fiddler
scoop install extras/neatdownloadmanager
scoop install extras/cheat-engine
scoop install extras/qimgv-video
scoop install extras/clash-verge-rev
scoop install extras/64gram

