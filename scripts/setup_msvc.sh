#!/bin/bash
# set -e  # 保留，但增加错误捕获

# 禁止路径转换
export MSYS2_ARG_CONV_EXCL="*"

# 1. 获取 VS 路径
VSWHERE_EXE="C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
VS_PATH=$("$VSWHERE_EXE" -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | tr -d '\r\n')
VCVARS_BAT="${VS_PATH}/VC/Auxiliary/Build/vcvarsall.bat"

echo "找到 Visual Studio 路径: ${VS_PATH}"

if [ -z "$VS_PATH" ]; then
    echo "❌ 未找到 Visual Studio 安装"
    exit 1
fi

pwsh -NoProfile -NonInteractive -Command "
    # 加载 DevShell 模块
    Import-Module (Join-Path \"${VS_PATH}\" 'Common7/Tools/Microsoft.VisualStudio.DevShell.dll') -ErrorAction Stop

    # 进入 VS 开发环境（架构设为 amd64，可根据需要改为 x86、arm64 等）
    Enter-VsDevShell -VsInstallPath \"${VS_PATH}\" -Arch amd64 -SkipAutomaticLocation -ErrorAction Stop

    # 获取当前进程的所有环境变量，过滤出我们需要的（或全部导出）
    # 推荐导出所有变量，因为 MSVC 依赖很多变量（PATH, INCLUDE, LIB, LIBPATH, WindowsSdkDir, ...）
    Get-ChildItem env: | ForEach-Object {
        # 只输出环境变量名和值，格式为 KEY=VALUE
        # 注意：如果值包含换行符等特殊字符，需额外处理，但通常没有
        Write-Output \"\$(\$_.Name)=\$(\$_.Value)\"
    }
" | grep -E '^(PATH|INCLUDE|LIB|LIBPATH|VCINSTALLDIR|WindowsSdkDir|WindowsSDKVersion|VCToolsInstallDir)=' | sed 's/\r$//' >> "$GITHUB_ENV"

# 3. 检查是否成功写入
echo "📋 已写入 GITHUB_ENV 的内容（前几行）："
head -n 5 "$GITHUB_ENV" || echo "⚠️ 警告：GITHUB_ENV 为空"

echo "✅ MSVC 环境注入完成"
# 验证 cl.exe（此时 PATH 应已更新）
which cl.exe || echo "⚠️ 未找到 cl.exe（请检查上方环境变量）"