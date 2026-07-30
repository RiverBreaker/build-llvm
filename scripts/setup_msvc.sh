# 1. 定义 vswhere.exe 的 Windows 绝对路径
VSWHERE_EXE="C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"

# 2. 调用 vswhere 获取最新的 VS 安装路径
# 使用 cmd.exe //c 避免 Git Bash 的 POSIX 路径自动转换陷阱
# 使用 tr -d '\r\n' 清除 Windows 换行符，确保 Bash 变量干净
VS_PATH=$(cmd.exe //c "\"${VSWHERE_EXE}\"" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | tr -d '\r\n')

# 3. 拼接 vcvarsall.bat 的路径 (保持 Windows 路径格式，因为即将传给 cmd)
VCVARS_BAT="${VS_PATH}\VC\Auxiliary\Build\vcvarsall.bat"

echo "找到 Visual Studio 路径: ${VS_PATH}"
echo "vcvarsall.bat 路径: ${VCVARS_BAT}"

# 4. 执行 vcvarsall.bat 并提取核心环境变量写入 $GITHUB_ENV
# 解释：
# - cmd.exe //c "call ... && set" : 运行批处理并输出所有环境变量
# - grep -E '^(PATH|INCLUDE|LIB|LIBPATH|VCINSTALLDIR|WindowsSdkDir|WindowsSDKVersion|VCToolsInstallDir)=' : 只提取 MSVC 相关的核心变量，避免污染 GITHUB_ENV
# - sed 's/\r$//' : 彻底清除行尾的 \r，确保符合 GitHub Actions 的 KEY=VALUE 格式要求
cmd.exe //c "call \"${VCVARS_BAT}\" x64 && set" | \
grep -E '^(PATH|INCLUDE|LIB|LIBPATH|VCINSTALLDIR|WindowsSdkDir|WindowsSDKVersion|VCToolsInstallDir)=' | \
sed 's/\r$//' >> "$GITHUB_ENV"

echo "✅ MSVC 环境已成功注入到 GITHUB_ENV"

# (可选) 验证一下 cl.exe 是否可用
echo "验证 cl.exe 路径:"
which cl.exe || echo "未找到 cl.exe (请检查上方日志)"