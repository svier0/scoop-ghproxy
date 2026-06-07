# scoop-ghproxy

## Scoop 国内使用无法访问github的问题
- 如果你安装scoop之前已经开启了科学上网，请关闭这个网页
- 如果你没有使用网络代理软件的习惯，不想操作繁琐的换源配置，只想在国内网络快速使用scoop，请往下看

## 前提条件

[PowerShell](https://learn.microsoft.com/zh-cn/powershell/) 版本在 5.1 或以上，如果没有 PowerShell 大于 5.1 版本，可以下载安装 [PowerShell Core](https://github.com/PowerShell/PowerShell)。运行以下命令查看：

```powershell
$PSVersionTable.PSVersion.Major # 应该 >= 5.1
```

其次，允许本地运行 PowerShell 脚本，以管理员打开 PowerShell，运行以下命令，回答 Y：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 使用说明

1. 未安装过scoop

打开 PowerShell，运行以下命令，

```powershell
irm https://ghfast.top/https://raw.githubusercontent.com/svier0/scoop-ghproxy/master/script.ps1 | iex
```
按照提示 输入 5 回车
输入代理网址 如：https://ghfast.top 或 https://gh-proxy.com
下一步
没有下一步了 你可以愉快的scoop install 你需要的软件名称

2. 已安装过scoop

打开 PowerShell，运行以下命令，

```powershell
irm https://ghfast.top/https://raw.githubusercontent.com/svier0/scoop-ghproxy/master/script.ps1 | iex
```
按照提示 输入 4 回车
输入代理网址 如：https://ghfast.top 或 https://gh-proxy.com
下一步
没有下一步了 你可以愉快的scoop install 你需要的软件名称

3. 检测当前scoop注入状态

```powershell
irm https://ghfast.top/https://raw.githubusercontent.com/svier0/scoop-ghproxy/master/script.ps1 | iex
```
按照提示 输入 3 回车

4. 取消注入恢复scoop到原版

```powershell
irm https://ghfast.top/https://raw.githubusercontent.com/svier0/scoop-ghproxy/master/script.ps1 | iex
```
按照提示 输入 2 回车

5. 输入命令后输入1回车是干嘛的 跟4一样 不过不用再输入代理地址了 如果你之前设置过代理地址的话

6. 切换代理地址
```powershell
scoop config GITHUB_PROXY https://ghproxy.top
```

### 就一行命令 感觉其实不用写说明
<img width="957" height="1551" alt="PixPin_2026-06-07_17-29-26" src="https://github.com/user-attachments/assets/3b432700-4ba2-4efa-84de-d41dd89b39d3" />

还可以参考example.ps1将自己常用的软件写进脚本，重装系统或者换一台电脑后一行命令直接全部安装
<img width="1017" height="3031" alt="PixPin_2026-06-08_01-27-45" src="https://github.com/user-attachments/assets/c9734051-9bb7-47c9-8c31-aace8073e9ad" />
