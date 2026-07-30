#!/usr/bin/env python3
"""
调用 build.sh 的 Python 包装脚本
用法: python build.py --build-dir=/path --build-arch=x64 ...
"""

import argparse
import subprocess
import sys
from pathlib import Path

if sys.platform == "win32":
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def main():
    parser = argparse.ArgumentParser(description="调用 build 进行 LLVM 构建")
    parser.add_argument("--build-dir", required=True, help="构建目录")
    parser.add_argument("--build-arch", required=True, help="目标架构")
    parser.add_argument("--build-type", required=True, help="构建类型 (如 Release)")
    parser.add_argument("--build-project", required=True, help="项目名称 (如 base, flang)")
    parser.add_argument("--install-dir", required=True, help="安装目录")
    parser.add_argument("--src-dir", required=True, help="源码目录")

    args = parser.parse_args()

    # 确定 build.sh 的位置（假设与本脚本同目录）
    script_dir = Path(__file__).parent.resolve()
    build_script = script_dir / "build"
    bash_exe = r"C:/Program Files/Git/bin/bash.exe"

    if not build_script.is_file():
        print(f"[ERROR] 找不到构建脚本: {build_script}", file=sys.stderr)
        sys.exit(1)

    # 构建参数列表，使用 --key=value 格式
    cmd = [
        bash_exe,
        str(build_script),
        f"--build-dir={args.build_dir}",
        f"--build-arch={args.build_arch}",
        f"--build-type={args.build_type}",
        f"--build-project={args.build_project}",
        f"--install-dir={args.install_dir}",
        f"--src-dir={args.src_dir}",
    ]

    print(f"[INFO] 执行命令: {' '.join(cmd)}")
    try:
        # 直接执行，让 build.sh 继承当前环境变量
        result = subprocess.run(cmd, check=False)
        sys.exit(result.returncode)
    except FileNotFoundError:
        print(f"[ERROR] 无法执行脚本，请确保 bash 可用且脚本有执行权限", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n[INFO] 用户中断", file=sys.stderr)
        sys.exit(130)

if __name__ == "__main__":
    main()