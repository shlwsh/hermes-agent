#!/usr/bin/env bash
# mygit 环境检查与初始化脚本
# 用法: bash .agent/skills/mygit/scripts/setup-check.sh

set -e

echo "🔍 mygit 环境检查"
echo "================================"

# 1. 检查 Bun
if command -v bun &> /dev/null; then
  echo "✅ Bun: $(bun --version)"
else
  echo "❌ Bun 未安装，请访问 https://bun.sh 安装"
  exit 1
fi

# 2. 检查 Git
if command -v git &> /dev/null; then
  echo "✅ Git: $(git --version)"
else
  echo "❌ Git 未安装"
  exit 1
fi

# 3. 检查 Git 仓库
if git rev-parse --git-dir &> /dev/null; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  REMOTE=$(git remote | head -1)
  echo "✅ Git 仓库: 分支=$BRANCH, 远程=$REMOTE"
else
  echo "❌ 当前目录不是 Git 仓库"
  exit 1
fi

# 4. 检查 .env.mygit
if [ -f ".env.mygit" ]; then
  # 检查必填字段
  HAS_KEY=$(grep -c "DASHSCOPE_API_KEY=sk-" .env.mygit 2>/dev/null || echo "0")
  HAS_URL=$(grep -c "DASHSCOPE_BASE_URL=" .env.mygit 2>/dev/null || echo "0")
  HAS_MODEL=$(grep -c "DASHSCOPE_MODEL=" .env.mygit 2>/dev/null || echo "0")

  if [ "$HAS_KEY" -gt 0 ] && [ "$HAS_URL" -gt 0 ] && [ "$HAS_MODEL" -gt 0 ]; then
    MODEL=$(grep "DASHSCOPE_MODEL=" .env.mygit | cut -d'=' -f2)
    echo "✅ .env.mygit: 配置完整 (模型=$MODEL)"
  else
    echo "⚠️  .env.mygit: 配置不完整，请检查必填字段"
  fi
else
  echo "❌ .env.mygit 不存在"
  echo ""
  echo "   请从模板创建配置文件："
  echo "   cp .agent/skills/mygit/resources/env.mygit.template .env.mygit"
  echo "   然后编辑 .env.mygit 填入你的 API 密钥"
  exit 1
fi

# 5. 检查 .gitignore
if grep -q ".env.mygit" .gitignore 2>/dev/null; then
  echo "✅ .gitignore: 已排除 .env.mygit"
else
  echo "⚠️  .gitignore: 未排除 .env.mygit，建议添加"
fi

# 6. 检查 package.json 脚本
if grep -q '"mygit"' package.json 2>/dev/null; then
  echo "✅ package.json: mygit 脚本已配置"
else
  echo "⚠️  package.json: 未找到 mygit 脚本"
fi

echo ""
echo "================================"
echo "✨ 检查完成！可使用 'bun run mygit' 提交代码"
