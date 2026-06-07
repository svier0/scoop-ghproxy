# scoop-github-proxy.ps1
# 为 Scoop 的 GitHub 下载自动拼接代理，解决国内访问 GitHub 不稳定的问题
#
# 用法:
#   irm https://gh-proxy.com/svier0/scoop-ghproxy/script.ps1 | iex    # 交互菜单（推荐）
#   本地运行也支持直接传参:
#   .\scoop-github-proxy.ps1 -Action enable
#   .\scoop-github-proxy.ps1 -Action disable
#   .\scoop-github-proxy.ps1 -Action status
#   .\scoop-github-proxy.ps1 -Action enable -ProxyUrl https://mirror.ghproxy.com

param(
    [ValidateSet('enable', 'disable', 'status')]
    [string]$Action = '',
    [string]$ProxyUrl = 'https://gh-proxy.com'
)

$ErrorActionPreference = 'Stop'
$patchMarker = '# === SCOOP-GITHUB-PROXY-PATCHED ==='

# ============================================================
# 工具函数
# ============================================================

function Find-ScoopDir {
    if ($env:SCOOP -and (Test-Path $env:SCOOP)) { return $env:SCOOP }
    $default = "$env:USERPROFILE\scoop"
    if (Test-Path $default) { return $default }
    return $null
}

function Get-DownloadPs1 {
    $scoop = Find-ScoopDir
    if (!$scoop) { return $null }
    $path = "$scoop\apps\scoop\current\lib\download.ps1"
    if (Test-Path $path) { return $path }
    return $null
}

function Test-IsPatched {
    param([string]$Path)
    if (!(Test-Path $Path)) { return $false }
    $content = Get-Content $Path -Raw -Encoding UTF8
    return $content.Contains($patchMarker)
}

function Get-OrigPath {
    param([string]$Path)
    return "$Path.sgp-orig"
}

# ============================================================
# enable - 应用 patch
# ============================================================

function Enable-Proxy {
    $downloadPs1 = Get-DownloadPs1
    if (!$downloadPs1) {
        Write-Host "ERROR: 找不到 Scoop 安装目录下的 download.ps1" -ForegroundColor Red
        Write-Host "请确认 Scoop 已正确安装。默认路径: ~\scoop\apps\scoop\current\lib\download.ps1"
        Write-Host "如果使用了自定义路径，请确保 SCOOP 环境变量已设置。"
        exit 1
    }

    if (Test-IsPatched $downloadPs1) {
        Write-Host "INFO: download.ps1 已经 patch 过了，更新代理地址..."
        # 先 disable 再 enable，保证配置更新
        Disable-Proxy -Silent
    }

    $orig = Get-OrigPath $downloadPs1
    # 始终备份当前文件（处理 Scoop 更新后 download.ps1 版本变化的情况）
    Copy-Item $downloadPs1 $orig -Force
    Write-Host "OK: 已备份原始文件 -> download.ps1.sgp-orig"

    $content = Get-Content $downloadPs1 -Raw -Encoding UTF8

    # 健壮的注入策略：
    #   1. 逐行扫描，用大括号计数定位 handle_special_urls 函数的范围
    #   2. 从函数末尾向前搜索最后一个 return $url
    #   3. 在 return $url 上一行注入代理代码
    # 不依赖缩进宽度、空行数量、注释文本等脆弱细节。

    $lines = $content -split '\r?\n'
    $funcStart = -1
    $funcEnd = -1
    $braceCount = 0
    $inFunction = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if (-not $inFunction -and $line -match '^\s*function\s+handle_special_urls\s*\(') {
            $funcStart = $i
            $inFunction = $true
        }
        if ($inFunction) {
            $opens = ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count
            $closes = ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count
            $braceCount += ($opens - $closes)
            if ($braceCount -le 0) {
                $funcEnd = $i
                break
            }
        }
    }

    if ($funcStart -lt 0 -or $funcEnd -lt 0) {
        Write-Host "ERROR: 无法定位 handle_special_urls 函数" -ForegroundColor Red
        Write-Host "请检查 Scoop 版本或提交 Issue。"
        exit 1
    }

    # 从函数末尾向前找最后一个 return $url
    $lastReturnLine = -1
    for ($i = $funcEnd - 1; $i -gt $funcStart; $i--) {
        if ($lines[$i] -match '^\s*return\s+\$url\s*$') {
            $lastReturnLine = $i
            break
        }
    }

    if ($lastReturnLine -lt 0) {
        Write-Host "ERROR: 在 handle_special_urls 函数中未找到 return `$url" -ForegroundColor Red
        Write-Host "请检查 Scoop 版本或提交 Issue。"
        exit 1
    }

    # 提取 return $url 行的缩进，保持 patch 代码缩进一致
    $indent = ''
    if ($lines[$lastReturnLine] -match '^(\s*)') {
        $indent = $Matches[1]
    }

    $injectedBlock = @"
${indent}# === SCOOP-GITHUB-PROXY-PATCHED ===
${indent}# 自动为 GitHub 下载 URL 拼接代理，可通过 scoop config GITHUB_PROXY 配置
${indent}`$ghProxy = get_config GITHUB_PROXY
${indent}if (
${indent}    `$ghProxy -and
${indent}    `$url -match '^https?://(github\.com|raw\.githubusercontent\.com|api\.github\.com|objects-githubusercontent\.com|release-assets\.githubusercontent\.com|codeload\.github\.com|gist\.githubusercontent\.com)/'
${indent}) {
${indent}    `$url = "`$ghProxy/`$url"
${indent}}
${indent}# === END SCOOP-GITHUB-PROXY ===
"@

    # 在 return $url 行之前插入（注入块先按行展开再拼入数组）
    $blockLines = $injectedBlock -split '\r?\n'
    $newLines = $lines[0..($lastReturnLine - 1)] + $blockLines + $lines[$lastReturnLine..($lines.Count - 1)]
    $newContent = $newLines -join "`r`n"

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($downloadPs1, $newContent, $utf8NoBom)

    Write-Host "OK: download.ps1 已 patch ($downloadPs1)"

    # 写入 Scoop 配置
    $scoopDir = Find-ScoopDir
    if ($scoopDir) {
        $configFile = "$scoopDir\config.json"
        $config = @{}
        if (Test-Path $configFile) {
            try {
                $rawJson = Get-Content $configFile -Raw -Encoding UTF8
                if ($rawJson.Trim() -eq '') { $config = @{} }
                else {
                    $config = $rawJson | ConvertFrom-Json | ForEach-Object {
                        $hash = @{}; $_.PSObject.Properties | ForEach-Object { $hash[$_.Name] = $_.Value }; $hash
                    }
                }
                if (!$config) { $config = @{} }
            } catch {
                Write-Host "WARNING: config.json 解析失败，将备份后重新创建" -ForegroundColor Yellow
                Copy-Item $configFile "$configFile.bak-$(Get-Date -Format 'yyyyMMddHHmmss')"
                $config = @{}
            }
        }
        $config['GITHUB_PROXY'] = $ProxyUrl
        $config | ConvertTo-Json -Depth 3 | ForEach-Object {
            [System.IO.File]::WriteAllText($configFile, $_, $utf8NoBom)
        }
        Write-Host "OK: GITHUB_PROXY = $ProxyUrl"
    }

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  scoop-github-proxy 已启用！" -ForegroundColor Green
    Write-Host "  代理地址: $ProxyUrl" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
}

# ============================================================
# disable - 恢复原始文件
# ============================================================

function Disable-Proxy {
    param([switch]$Silent)

    $downloadPs1 = Get-DownloadPs1
    if (!$downloadPs1) {
        if (!$Silent) {
            Write-Host "ERROR: 找不到 Scoop 安装目录" -ForegroundColor Red
        }
        return
    }

    $orig = Get-OrigPath $downloadPs1
    if (Test-Path $orig) {
        Copy-Item $orig $downloadPs1 -Force
        Remove-Item $orig
        if (!$Silent) { Write-Host "OK: 已从 .sgp-orig 恢复原始文件" }
    } elseif (Test-IsPatched $downloadPs1) {
        # 没有备份但有 patch —— 尝试反向移除 patch
        $content = Get-Content $downloadPs1 -Raw -Encoding UTF8
        $pattern = '(?sm)^\s*# === SCOOP-GITHUB-PROXY-PATCHED ===.*?# === END SCOOP-GITHUB-PROXY ===\s*\r?\n'
        $newContent = $content -replace $pattern, ''
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($downloadPs1, $newContent, $utf8NoBom)
        if (!$Silent) { Write-Host "OK: 已移除 patch 代码（无备份文件，使用正则清理）" }
    } else {
        if (!$Silent) { Write-Host "INFO: download.ps1 未被 patch，无需操作" }
    }

    # 清除 Scoop 配置中的 GITHUB_PROXY
    $scoopDir = Find-ScoopDir
    if ($scoopDir) {
        $configFile = "$scoopDir\config.json"
        if (Test-Path $configFile) {
            try {
                $rawJson = Get-Content $configFile -Raw -Encoding UTF8
                if ($rawJson.Trim() -eq '') { return }
                $config = $rawJson | ConvertFrom-Json | ForEach-Object {
                    $hash = @{}; $_.PSObject.Properties | ForEach-Object { $hash[$_.Name] = $_.Value }; $hash
                }
                if ($config -and $config.ContainsKey('GITHUB_PROXY')) {
                    $config.Remove('GITHUB_PROXY')
                    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                    $configJson = $config | ConvertTo-Json -Depth 3
                    [System.IO.File]::WriteAllText($configFile, $configJson, $utf8NoBom)
                    if (!$Silent) { Write-Host "OK: 已清除 GITHUB_PROXY 配置" }
                }
            } catch {
                if (!$Silent) {
                    Write-Host "WARNING: config.json 解析失败，配置清除已跳过（不影响功能）" -ForegroundColor Yellow
                }
            }
        }
    }

    if (!$Silent) {
        Write-Host ""
        Write-Host "scoop-github-proxy 已禁用。" -ForegroundColor Yellow
        Write-Host ""
    }
}

# ============================================================
# status - 查看当前状态
# ============================================================

function Show-Status {
    Write-Host ""
    Write-Host "=== scoop-github-proxy 状态 ===" -ForegroundColor Cyan
    Write-Host ""

    $scoopDir = Find-ScoopDir
    if (!$scoopDir) {
        Write-Host "Scoop: 未安装" -ForegroundColor Red
        return
    }
    Write-Host "Scoop 路径: $scoopDir"

    $downloadPs1 = Get-DownloadPs1
    if (!$downloadPs1) {
        Write-Host "download.ps1: 未找到（Scoop 可能未完成初始化）" -ForegroundColor Red
        return
    }

    $patched = Test-IsPatched $downloadPs1
    $hasBackup = Test-Path (Get-OrigPath $downloadPs1)

    Write-Host "download.ps1: $downloadPs1"
    Write-Host -NoNewline '已 Patch:   '; if ($patched) { Write-Host '是' -ForegroundColor Green } else { Write-Host '否' -ForegroundColor Yellow }
    Write-Host -NoNewline '有备份:     '; if ($hasBackup) { Write-Host '是 (download.ps1.sgp-orig)' } else { Write-Host '否' -ForegroundColor Yellow }

    # 读代理地址
    $proxyAddr = '未设置'
    $configFile = "$scoopDir\config.json"
    if (Test-Path $configFile) {
        try {
            $config = Get-Content $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($config.GITHUB_PROXY) {
                $proxyAddr = $config.GITHUB_PROXY
            }
        } catch { }
    }
    Write-Host "代理地址:   $proxyAddr"
    Write-Host ""

    if ($patched) {
        Write-Host "✓ 代理已启用，GitHub 下载会自动走 $proxyAddr" -ForegroundColor Green
        Write-Host "  如 Scoop 自更新后代理失效，重新运行本脚本即可。"
    } else {
        Write-Host "✗ 代理未启用。运行本脚本（不加参数）即可启用。" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Get-ProxyConfig {
    $scoopDir = Find-ScoopDir
    if (!$scoopDir) { return $null }
    $configFile = "$scoopDir\config.json"
    if (!(Test-Path $configFile)) { return $null }
    try {
        $config = Get-Content $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
        return $config.GITHUB_PROXY
    } catch { return $null }
}

# ============================================================
# 交互菜单（irm ... | iex 入口）
# ============================================================

function Show-Menu {
    Write-Host ''
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host '      Scoop GitHub Proxy' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  1. 开始注入 (默认)'
    Write-Host '  2. 恢复文件'
    Write-Host '  3. 查看状态'
    Write-Host '  4. 切换代理地址'
    Write-Host ''
    $choice = Read-Host '请输入 [1-4]'
    if ($choice -eq '' -or $choice -eq '1') {
        # 如果已有配置，沿用现有代理地址
        $existing = Get-ProxyConfig
        if ($existing) { $script:ProxyUrl = $existing }
        Enable-Proxy
    } elseif ($choice -eq '2') {
        Disable-Proxy
    } elseif ($choice -eq '3') {
        Show-Status
    } elseif ($choice -eq '4') {
        $newProxy = Read-Host '请输入新的代理地址'
        if ($newProxy) {
            $script:ProxyUrl = $newProxy
            Enable-Proxy
        } else {
            Write-Host '未输入代理地址，已取消。' -ForegroundColor Yellow
        }
    } else {
        Write-Host "无效输入: $choice" -ForegroundColor Red
    }
}

# ============================================================
# Main
# ============================================================

if ($Action) {
    # 本地直接传参运行
    switch ($Action) {
        'enable'  { Enable-Proxy }
        'disable' { Disable-Proxy }
        'status'  { Show-Status }
    }
} else {
    # irm ... | iex 入口，显示交互菜单
    Show-Menu
}
