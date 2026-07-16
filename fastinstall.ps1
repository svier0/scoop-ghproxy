# =============================================================================
# Win11 Scoop安装脚本
# 用法: irm https://ghfast.top/https://raw.githubusercontent.com/svier0/scoop-ghproxy/master/fastinstall.ps1 | iex
# 功能: 快速在D盘安装Scoop
# =============================================================================

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 有需要可以通过设置环境变量，来设置安装位置
# 设置主目录（应用默认装这里）
$env:SCOOP='D:\Scoop'
[Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')

Write-Host "安装scoop 并注入 scoop-ghproxy"
$ghproxy_hiddenmenu = $true
irm "https://gh-proxy.com/https://raw.githubusercontent.com/svier0/scoop-ghproxy/master/script.ps1" | iex
Install-Scoop

# 设置缓存目录（下载的安装包存这里）
scoop config cache_path 'D:\Scoop\cache'

#添加仓库
#scoop bucket add main         https://gh-proxy.com/https://github.com/ScoopInstaller/Main
#scoop bucket add extras       https://gh-proxy.com/https://github.com/ScoopInstaller/Extras
#scoop bucket add nonportable  https://gh-proxy.com/https://github.com/ScoopInstaller/Nonportable
#scoop bucket add sysinternals https://gh-proxy.com/https://github.com/niheaven/scoop-sysinternals
#scoop bucket add svier0       https://gh-proxy.com/https://github.com/svier0/scoopbucket

#浅克隆 不附带仓库历史
git clone --depth 1 https://gh-proxy.com/https://github.com/ScoopInstaller/Main         "$env:SCOOP\buckets\main"
git clone --depth 1 https://gh-proxy.com/https://github.com/ScoopInstaller/Extras       "$env:SCOOP\buckets\extras"
git clone --depth 1 https://gh-proxy.com/https://github.com/ScoopInstaller/Nonportable  "$env:SCOOP\buckets\nonportable"
git clone --depth 1 https://gh-proxy.com/https://github.com/niheaven/scoop-sysinternals "$env:SCOOP\buckets\sysinternals"
git clone --depth 1 https://gh-proxy.com/https://github.com/svier0/scoopbucket          "$env:SCOOP\buckets\svier0"



# end
