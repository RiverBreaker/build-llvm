#!/bin/bash
set -euo pipefail
export MSYS_NO_PATHCONV=1
build_type=""
install_dir=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --build-type=*)
            build_type="${1#*=}"
            shift
            ;;
		--install-dir=*)
			install_dir="${1#*=}"
			shift
			;;
        *)
            echo "未知选项: $1"
            exit 1
            ;;
    esac
done
if [[ "${build_type}" == "Release" ]]; then
    echo "[INFO] Stripping SDK files, keeping toolchain only..."

    # ====== 删除 C++ 开发库（官方不装这些）======
    rm -f "${install_dir}"/lib/libLLVM*.lib
    rm -f "${install_dir}"/lib/liblld*.lib
    rm -f "${install_dir}"/lib/libmlir*.lib
    rm -f "${install_dir}"/lib/libMLIR*.lib
    rm -f "${install_dir}"/lib/libflang*.lib
    rm -f "${install_dir}"/lib/libFortran*.lib
    rm -f "${install_dir}"/lib/libclang*.lib
    # 但保留 C API 库（官方有这些）：
    # libclang.lib, LLVM-C.lib, LTO.lib, Remarks.lib, liblldb.lib, libomp.lib

    # ====== 删除 C++ 开发头文件（官方不装这些）======
    rm -rf "${install_dir}"/include/llvm
    rm -rf "${install_dir}"/include/clang     # C++ 头文件，不是 clang-c/
    rm -rf "${install_dir}"/include/lld
    rm -rf "${install_dir}"/include/lldb
    rm -rf "${install_dir}"/include/mlir
    rm -rf "${install_dir}"/include/mlir-c
    rm -rf "${install_dir}"/include/flang
    # 保留：include/clang-c/（C API）、include/llvm-c/（C API）
    # 保留：lib/clang/*/include/（内置头文件）

    # ====== 删除 CMake 配置（官方只有 LLVMConfigExtensions.cmake）======
    rm -rf "${install_dir}"/lib/cmake

    # ====== 删除 MLIR 工具 ======
    rm -f "${install_dir}"/bin/mlir-*
    rm -f "${install_dir}"/bin/tblgen-liblinalg*
    rm -f "${install_dir}"/bin/fir-opt.exe

    # ====== 删除 LLVM 开发工具（官方不装这些）======
    rm -f "${install_dir}"/bin/opt.exe
    rm -f "${install_dir}"/bin/llc.exe
    rm -f "${install_dir}"/bin/llvm-*.exe
    # 但保留官方有的：llvm-ar, llvm-nm, llvm-objdump, llvm-profdata 等
    # 所以不要 rm -f bin/llvm-*.exe！改为精确删除：
    rm -f "${install_dir}"/bin/opt.exe
    rm -f "${install_dir}"/bin/llc.exe
    rm -f "${install_dir}"/bin/FileCheck.exe
    rm -f "${install_dir}"/bin/count.exe
    rm -f "${install_dir}"/bin/not.exe
    rm -f "${install_dir}"/bin/yaml2obj.exe
    rm -f "${install_dir}"/bin/obj2yaml.exe
    rm -f "${install_dir}"/bin/verify-uselistorder.exe
    rm -f "${install_dir}"/bin/bugpoint.exe
    rm -f "${install_dir}"/bin/llvm-bcanalyzer.exe
    rm -f "${install_dir}"/bin/llvm-extract.exe
    rm -f "${install_dir}"/bin/llvm-link.exe
    rm -f "${install_dir}"/bin/llvm-lto*.exe
    rm -f "${install_dir}"/bin/llvm-reduce.exe
    rm -f "${install_dir}"/bin/llvm-remarkutil.exe
    rm -f "${install_dir}"/bin/llvm-split.exe
    rm -f "${install_dir}"/bin/llvm-stress.exe
    rm -f "${install_dir}"/bin/llvm-tblgen.exe
    rm -f "${install_dir}"/bin/llvm-ifs.exe
    rm -f "${install_dir}"/bin/llvm-gsymutil.exe
    rm -f "${install_dir}"/bin/llvm-debuginfod*.exe
    rm -f "${install_dir}"/bin/llvm-mc.exe
    rm -f "${install_dir}"/bin/llvm-readelf.exe
    rm -f "${install_dir}"/bin/llvm-tli-checker.exe
    rm -f "${install_dir}"/bin/llvm-windres.exe
    rm -f "${install_dir}"/bin/llvm-xray.exe

    echo "[INFO] Release toolchain: SDK files stripped"
fi