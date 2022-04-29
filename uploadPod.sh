#!/bin/sh
POD_NAME="CSAPIService"
# 新版本号
NEW_VERSION_NUMBER=$1
# 提交信息
COMMIT_MESSAGE=$2

CURRENT_PATH=$(cd `dirname $0`; pwd)
cd ${CURRENT_PATH}

if [ $NEW_VERSION_NUMBER ]; then
echo ${NEW_VERSION_NUMBER}
fi
if [ $COMMIT_MESSAGE ]; then
echo ${COMMIT_MESSAGE}
fi


VERSION_NUMBER=`grep -E 's.version.*=' ${POD_NAME}.podspec | awk -F \' '{print $2}'`

LINE_NUMBER=`grep -nE 's.version.*=' ${POD_NAME}.podspec | cut -d : -f1`
sed -i "" "${LINE_NUMBER}s/${VERSION_NUMBER}/${NEW_VERSION_NUMBER}/g" ${POD_NAME}.podspec

git add .
git commit -m ${NEW_VERSION_NUMBER}${COMMIT_MESSAGE}
git tag ${NEW_VERSION_NUMBER}
git push --tags

pod trunk push ${POD_NAME}.podspec
