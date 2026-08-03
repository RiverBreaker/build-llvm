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

if [[ "${build_type}" == "Release" ]]; then
	cd "${install_dir}"

	ZIP_FILE="${base_name}.7z"

	echo "[INFO] 开始打包到：${package_dir}/${base_name}.7z"
	echo "[INFO] 开始生成单文件 7z 压缩包"

	7z a -t7z "${package_dir}/${ZIP_FILE}" . -mx=6 -mmt=on || {
		echo "[ERROR] 生成单文件压缩包失败"
		exit 1
	}
	echo "[INFO] 单文件压缩包生成完成"
elif [[ "${build_type}" == "RelWithDebInfo" ]]; then
	OUTPUT_PATH="${package_dir}/${base_name}.7z"
	# 执行 7z 分卷压缩
	cd "${install_dir}"
	echo "[INFO] 开始分卷压缩"
	if 7z a -t7z "$OUTPUT_PATH" . -v1950m -mx=5 -mmt=on; then
		echo "[INFO] 分卷压缩成功, 输出前缀: $OUTPUT_PATH"
	else
		echo "::error::分卷压缩失败"
		exit 1
	fi
else
	echo "[ERROR] 不是支持的类型 ${build_type}"
	exit 1
fi