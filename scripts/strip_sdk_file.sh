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
if [[ -z "${build_type}" || -z "${install_dir}" ]]; then
    echo "[ERROR] 缺少必要参数: --build-type --install-dir"
    exit 1
fi

if [[ ! -d "${install_dir}" ]]; then
    echo "[ERROR] 安装目录不存在: ${install_dir}"
    exit 1
fi
if [[ "${build_type}" == "Release" ]]; then
    echo "[INFO] Stripping SDK files, keeping toolchain only..."
	rm -rf "${install_dir}/include/clang"
	rm -rf "${install_dir}/include/clang-tidy"
	rm -rf "${install_dir}/include/llvm"
	rm -rf "${install_dir}/include/mlir"
	rm -rf "${install_dir}/include/mlir-c"
	rm -rf "${install_dir}/include/lld"
	rm -rf "${install_dir}/include/lldb"

	rm -rf "${install_dir}/lib/cmake/clang"
	rm -rf "${install_dir}/lib/cmake/flang"
	rm -rf "${install_dir}/lib/cmake/lld"
	rm -rf "${install_dir}/lib/cmake/mlir"
	rm -rf "${install_dir}/lib/objects-Release"

	LLVM_CMAKE_DIR="${install_dir}/lib/cmake/llvm"

	if [[ -d "${LLVM_CMAKE_DIR}" ]]; then
		find "${LLVM_CMAKE_DIR}" \
			-mindepth 1 \
			-maxdepth 1 \
			! -name 'LLVMConfigExtensions.cmake' \
			-exec rm -rf -- {} +
	fi
	# rm -rf "${install_dir}/lib/cmake/llvm/*" # 需要保留LLVMConfigExtensions.cmake

	find "${install_dir}/lib" \
		-maxdepth 1 \
		-type f \
		-name '*.lib' \
		! -name 'libclang.lib' \
		! -name 'liblldb.lib' \
		! -name 'libomp.lib' \
		! -name 'LLVM-C.lib' \
		! -name 'LTO.lib' \
		! -name 'Remarks.lib' \
		! -name 'libiomp5md.lib' \
		-delete
	# rm -rf "${install_dir}/lib/*.lib" # 需要保留libclang.lib、liblldb.lib、libomp.lib、LLVM-C.lib、LTO.lib、Remarks.lib

	find "${install_dir}" \
    -type f \
    \( -name '*.pdb' -o -name '*.ilk' \) \
    -delete 2>/dev/null || true

    echo "[INFO] Release toolchain: SDK files stripped"
elif [[ "${build_type}" == "RelWithDebInfo" ]]; then
	echo "[INFO] Skip strip for RelWithDebInfo"
else
    echo "[ERROR] 不支持的构建类型: ${build_type}"
    exit 1
fi