### 发布新版本
sh uploadPod.sh {version}

### 更新文档
```shell
# 安装
gem install --user-install jazzy
export PATH="$(ruby -e 'puts Gem.user_dir')/bin:$PATH"

# 实现
cd Example
jazzy
```