#!/bin/bash
set -euo pipefail
export MSYS_NO_PATHCONV=1
build_type=""
install_dir=""
package_dir=""
base_name=""

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
		--package-dir=*)
			package_dir="${1#*=}"
			shift
			;;
		--base-name=*)
			base_name="${1#*=}"
			shift ;;
        *)
            echo "未知选项: $1"
            exit 1
            ;;
    esac
done
if [[ -z "${build_type}" || -z "${install_dir}" || -z "${package_dir}" || -z "${base_name}" ]]; then
    echo "[ERROR] 缺少必要参数: --build-type --install-dir --package-dir --base-name"
    exit 1
fi
if [[ ! -d "${install_dir}" ]]; then
    echo "[ERROR] 安装目录不存在: ${install_dir}"
    exit 1
fi
if [[ ! -d "${package_dir}" ]]; then
	mkdir -p "${package_dir}"
fi

echo "::group::[INFO] 安装目录体积分析"
cd "${install_dir}"
du -sh . || true
find . -type f \( -iname '*.pdb' -o -iname '*.ilk' \) -printf '%s\n' |
	awk '{ bytes += $1; count += 1 } END { printf "PDB/ILK: %d files, %.2f GiB\n", count, bytes / 1073741824 }'
echo "[INFO] 最大的 30 个文件（字节 路径）："
find . -type f -printf '%s\t%p\n' | sort -nr | sed -n '1,30p'
echo "::endgroup::"

if [[ "${build_type}" == "Release" ]]; then
	cd "${install_dir}"

	ZIP_FILE="${base_name}.7z"

	echo "[INFO] 开始打包到：${package_dir}/${base_name}.7z"
	echo "[INFO] 开始生成单文件 7z 压缩包"

	7z a -t7z "${package_dir}/${ZIP_FILE}" . -mx=7 -mmt=on -bsp1 -bb2 || {
		echo "[ERROR] 生成单文件压缩包失败"
		exit 1
	}
	echo "[INFO] 单文件压缩包生成完成"
elif [[ "${build_type}" == "RelWithDebInfo" ]]; then
	SDK_OUTPUT_PATH="${package_dir}/${base_name}.7z"
	SYMBOLS_OUTPUT_PATH="${package_dir}/${base_name}-symbols.7z"
	cd "${install_dir}"

	rm -f "${SDK_OUTPUT_PATH}" "${SDK_OUTPUT_PATH}".*
	rm -f "${SYMBOLS_OUTPUT_PATH}" "${SYMBOLS_OUTPUT_PATH}".*

	echo "[INFO] 开始压缩 SDK（排除 PDB/ILK）"
	if 7z a -t7z "${SDK_OUTPUT_PATH}" . \
		-xr!'*.pdb' -xr!'*.ilk' \
		-mx=7 -mmt=on -bsp1; then
		echo "[INFO] SDK 压缩成功, 输出前缀: ${SDK_OUTPUT_PATH}"
	else
		echo "::error::SDK 分卷压缩失败"
		exit 1
	fi

	if find . -type f \( -iname '*.pdb' -o -iname '*.ilk' \) -print -quit | grep -q .; then
		SYMBOLS_LIST="${package_dir}/${base_name}-symbols.list"
		find . -type f \( -iname '*.pdb' -o -iname '*.ilk' \) \
			-printf '%P\n' | sort -u > "${SYMBOLS_LIST}"

		echo "[INFO] 开始压缩调试符号，共 $(wc -l < "${SYMBOLS_LIST}") 个文件"
		if 7z a -t7z "${SYMBOLS_OUTPUT_PATH}" \
			@"${SYMBOLS_LIST}" -scsUTF-8 \
			-v1900m -mx=7 -mmt=on -bsp1; then
			rm -f "${SYMBOLS_LIST}"
			echo "[INFO] Symbols 压缩成功, 输出前缀: ${SYMBOLS_OUTPUT_PATH}"
		else
			rm -f "${SYMBOLS_LIST}"
			echo "::error::Symbols 分卷压缩失败"
			exit 1
		fi
	else
		echo "[INFO] 未发现 PDB/ILK，跳过 symbols 包"
	fi
else
	echo "[ERROR] 不是支持的类型 ${build_type}"
	exit 1
fi