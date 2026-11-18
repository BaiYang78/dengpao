#!/usr/bin/env bash
# 用法: bash push_to_github.sh <GitHub用户名> <PersonalAccessToken> [仓库名]
# 作用: 创建(或复用)GitHub 仓库并把当前目录代码推送上去
set -e

USERNAME="$1"
TOKEN="$2"
REPO="${3:-bulb-demo}"

if [ -z "$USERNAME" ] || [ -z "$TOKEN" ]; then
  echo "缺少参数。用法: bash push_to_github.sh <用户名> <Token> [仓库名]"
  exit 1
fi

cd "$(dirname "$0")"

echo "==> 创建仓库 ${USERNAME}/${REPO}（已存在则忽略错误）"
curl -s -o /dev/null -w "API HTTP %{http_code}\n" -X POST https://api.github.com/user/repos \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -d "{\"name\":\"${REPO}\",\"private\":false,\"description\":\"Bulb toggle demo - deployed on Surge\"}"

echo "==> 配置远程地址"
git remote remove origin 2>/dev/null || true
git remote add origin "https://${USERNAME}:${TOKEN}@github.com/${USERNAME}/${REPO}.git"

echo "==> 切到 main 分支并推送"
git branch -M main
git push -u origin main

echo "==> 清理带 token 的远程地址，改回公开地址"
git remote set-url origin "https://github.com/${USERNAME}/${REPO}.git"

echo "完成: https://github.com/${USERNAME}/${REPO}"
