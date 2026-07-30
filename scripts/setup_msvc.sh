#!/bin/bash
set -e  # 保留，但增加错误捕获

# 禁止路径转换
export MSYS2_ARG_CONV_EXCL="*"

# 1. 获取 VS 路径
VSWHERE_EXE="C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
VS_PATH=$("$VSWHERE_EXE" -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | tr -d '\r\n' | sed 's/\\/\//g')
VCVARS_BAT="${VS_PATH}/VC/Auxiliary/Build/vcvarsall.bat"

echo "找到 Visual Studio 路径: ${VS_PATH}"
echo "vcvarsall.bat 路径: ${VCVARS_BAT}"

# 2. 检查文件是否存在
if [ ! -f "${VCVARS_BAT}" ]; then
    echo "❌ 错误：找不到 vcvarsall.bat，请确认 VS 安装完整。"
    exit 1
fi

# 3. 执行 vcvarsall.bat，捕获输出和错误
echo "⏳ 正在执行 vcvarsall.bat ..."
CMD_OUTPUT=$(cmd.exe /c "call \"${VCVARS_BAT}\" x64 && set" 2>&1)
CMD_EXIT=$?

echo "cmd.exe 退出码: $CMD_EXIT"
if [ $CMD_EXIT -ne 0 ]; then
    echo "❌ cmd.exe 执行失败，错误输出："
    echo "$CMD_OUTPUT"
    exit $CMD_EXIT
fi

# 4. 提取需要的环境变量
echo "$CMD_OUTPUT" | grep -E '^(PATH|INCLUDE|LIB|LIBPATH|VCINSTALLDIR|WindowsSdkDir|WindowsSDKVersion|VCToolsInstallDir)=' | sed 's/\r$//' >> "$GITHUB_ENV"

# 5. 检查是否成功写入
echo "📋 已写入 GITHUB_ENV 的内容："
grep -E '^(PATH|INCLUDE|LIB|LIBPATH|VCINSTALLDIR|WindowsSdkDir|WindowsSDKVersion|VCToolsInstallDir)=' "$GITHUB_ENV" || echo "⚠️ 警告：没有任何匹配的环境变量被写入！"

echo "✅ MSVC 环境注入完成"
which cl.exe || echo "⚠️ 未找到 cl.exe (请检查上方的环境变量输出)"