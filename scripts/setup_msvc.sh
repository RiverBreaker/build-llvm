# 1. 使用正斜杠定义 vswhere.exe 路径（避免反斜杠转义）
VSWHERE_EXE="C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"

# 2. 直接调用 vswhere，无需通过 cmd.exe //c
#    - 用单引号包裹 '*' 防止被 Bash 展开
VS_PATH=$("$VSWHERE_EXE" -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | tr -d '\r\n')

# 3. vcvarsall.bat 路径同样使用正斜杠（Windows CMD 也接受正斜杠）
VCVARS_BAT="${VS_PATH}/VC/Auxiliary/Build/vcvarsall.bat"

echo "找到 Visual Studio 路径: ${VS_PATH}"
echo "vcvarsall.bat 路径: ${VCVARS_BAT}"

# 4. 执行 vcvarsall.bat 并提取环境变量（此处仍需要 cmd，因为 vcvarsall.bat 是批处理）
cmd.exe //c "call \"${VCVARS_BAT}\" x64 && set" | \
grep -E '^(PATH|INCLUDE|LIB|LIBPATH|VCINSTALLDIR|WindowsSdkDir|WindowsSDKVersion|VCToolsInstallDir)=' | \
sed 's/\r$//' >> "$GITHUB_ENV"

echo "✅ MSVC 环境已成功注入到 GITHUB_ENV"
which cl.exe || echo "未找到 cl.exe (请检查上方日志)"