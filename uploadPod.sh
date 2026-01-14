#!/bin/sh
POD_NAME="CSAPIService"
# 新版本号
NEW_VERSION_NUMBER=$1
# 提交信息
COMMIT_MESSAGE=$2

# shellcheck disable=SC2046
CURRENT_PATH=$(cd $(dirname "$0") || exit; pwd)
cd "${CURRENT_PATH}" || exit

# 检查版本号是否传入
if [ -z "$NEW_VERSION_NUMBER" ]; then
    echo "错误：版本号必须传入！"
    echo "用法: $0 <版本号> [提交信息]"
    exit 1
fi

echo "版本号: ${NEW_VERSION_NUMBER}"

# 如果没有传入commit message，使用版本号作为commit message
if [ -z "$COMMIT_MESSAGE" ]; then
    COMMIT_MESSAGE="${NEW_VERSION_NUMBER}"
    echo "提交信息: ${COMMIT_MESSAGE} (使用版本号)"
else
    echo "提交信息: ${COMMIT_MESSAGE}"
fi

# 检查tag是否已存在
if git rev-parse "${NEW_VERSION_NUMBER}" >/dev/null 2>&1; then
    echo "警告：tag ${NEW_VERSION_NUMBER} 已存在，正在删除..."
    # 删除本地tag
    git tag -d "${NEW_VERSION_NUMBER}"
    # 删除远程tag
    git push origin ":refs/tags/${NEW_VERSION_NUMBER}"
    echo "已删除本地和远程tag: ${NEW_VERSION_NUMBER}"
fi

VERSION_NUMBER=$(grep -E 's.version.*=' ${POD_NAME}.podspec | awk -F \' '{print $2}')

LINE_NUMBER=$(grep -nE 's.version.*=' ${POD_NAME}.podspec | cut -d : -f1)
sed -i "" "${LINE_NUMBER}s/${VERSION_NUMBER}/${NEW_VERSION_NUMBER}/g" ${POD_NAME}.podspec

git add .
git commit -m "${COMMIT_MESSAGE}"
git tag "${NEW_VERSION_NUMBER}"
git push --tags

pod trunk push ${POD_NAME}.podspec --allow-warnings
