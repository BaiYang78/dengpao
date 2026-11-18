#!/usr/bin/env bash
# 用法: bash push_to_github.sh <PersonalAccessToken>
# 作用: 推送当前目录到 https://github.com/BaiYan78/dengpao
#       仓库不存在则自动创建；自动适配本机代理与自签证书
set -e

TOKEN="$1"
USERNAME="BaiYan78"
REPO="dengpao"
NODE="C:/Users/511/.workbuddy/binaries/node/versions/22.22.2-2/node.exe"
PROXY="${HTTPS_PROXY:-http://127.0.0.1:3135}"

if [ -z "$TOKEN" ]; then
  echo "缺少 Token。用法: bash push_to_github.sh <PersonalAccessToken>"
  exit 1
fi

cd "$(dirname "$0")"

echo "==> 检查/创建仓库 ${USERNAME}/${REPO}"
NODE_TLS_REJECT_UNAUTHORIZED=0 "$NODE" - "$TOKEN" "$USERNAME" "$REPO" <<'EOF'
const [token, user, repo] = process.argv.slice(2);
const base = "https://api.github.com";
const headers = {
  "User-Agent": "push-helper",
  "Accept": "application/vnd.github+json",
  "Authorization": `Bearer ${token}`
};
(async () => {
  let r = await fetch(`${base}/repos/${user}/${repo}`, { headers, signal: AbortSignal.timeout(20000) });
  if (r.status === 200) { console.log("仓库已存在，直接推送"); return; }
  if (r.status !== 404) { console.log("检查仓库失败 HTTP", r.status, (await r.text()).slice(0,200)); process.exit(1); }
  r = await fetch(`${base}/user/repos`, {
    method: "POST", headers,
    body: JSON.stringify({ name: repo, private: false, description: "Bulb toggle demo - deployed on Surge" }),
    signal: AbortSignal.timeout(20000)
  });
  const t = await r.text();
  console.log("创建仓库 HTTP", r.status, r.status === 201 ? "OK" : t.slice(0,200));
  if (r.status !== 201) process.exit(1);
})().catch(e => { console.log("ERR", e.message); process.exit(1); });
EOF

echo "==> 配置带 token 的远程地址"
git remote remove origin 2>/dev/null || true
git remote add origin "https://${USERNAME}:${TOKEN}@github.com/${USERNAME}/${REPO}.git"

echo "==> 切到 main 分支并推送（经代理，跳过自签证书校验）"
git branch -M main
git -c http.proxy="$PROXY" -c https.proxy="$PROXY" -c http.sslVerify=false push -u origin main

echo "==> 清理带 token 的远程地址，改回公开地址"
git remote set-url origin "https://github.com/${USERNAME}/${REPO}.git"

echo "完成: https://github.com/${USERNAME}/${REPO}"
