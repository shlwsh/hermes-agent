import { $ } from "bun";
import fs from "fs";
import path from "path";

/**
 * AI Git 提交工具
 * 逻辑：检测变更 -> AI 生成提交信息 -> Commit -> Push
 */
async function main() {
  console.log("🚀 AI Git 提交工具启动");

  // 1. 验证 Git 仓库
  try {
    await $`git rev-parse --git-dir`.quiet();
  } catch (e) {
    console.error("❌ 错误: 当前目录不是一个有效的 Git 仓库");
    process.exit(1);
  }

  // 2. 加载配置
  const envPath = path.resolve(process.cwd(), ".env.mygit");
  if (!fs.existsSync(envPath)) {
    console.error(`❌ 错误: 找不到配置文件 .env.mygit`);
    console.error("请确保项目根目录下存在该文件，或从其他项目拷贝。");
    process.exit(1);
  }

  const envContent = fs.readFileSync(envPath, "utf-8");
  const env: Record<string, string> = {};
  envContent.split("\n").forEach(line => {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith("#")) {
      const firstEq = trimmed.indexOf("=");
      if (firstEq !== -1) {
        const key = trimmed.substring(0, firstEq).trim();
        const value = trimmed.substring(firstEq + 1).trim().replace(/^['"]|['"]$/g, "");
        if (key) env[key] = value;
      }
    }
  });

  const apiKey = env["DASHSCOPE_API_KEY"];
  const baseUrl = env["DASHSCOPE_BASE_URL"]?.replace(/\/$/, "");
  const model = env["DASHSCOPE_MODEL"];

  if (!apiKey || !baseUrl || !model) {
    console.error("❌ 错误: 配置文件中缺少必填项 (DASHSCOPE_API_KEY, DASHSCOPE_BASE_URL, DASHSCOPE_MODEL)");
    process.exit(1);
  }

  // 3. 检测变更
  console.log("📝 正在检查代码变更...");
  const statusOutput = (await $`git status --porcelain`.text()).trim();
  if (!statusOutput) {
    console.log("✅ 没有检测到代码变更");
    process.exit(0);
  }

  const changes = statusOutput.split("\n");
  console.log(`发现 ${changes.length} 个文件变更：`);
  changes.forEach(line => console.log(`  ${line}`));

  // 4. 版本文件检测
  const versionFiles = ["package.json", "pyproject.toml", "src-tauri/tauri.conf.json", "src-tauri/Cargo.toml"];
  const hasVersionChange = changes.some(line => versionFiles.some(vf => line.includes(vf)));
  if (hasVersionChange) {
    console.warn("\n⚠️ 检测到版本相关文件变更，建议使用相关的版本发布命令 (如 bun run release:tag)");
  }

  // 5. 生成提交信息
  console.log("\n🤖 正在使用 AI 生成提交信息...");
  let commitMsg = "";
  try {
    // 暂存所有变更以获取 diff
    await $`git add .`;
    const diff = (await $`git diff --cached`.text()).slice(0, 10000);
    
    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`
      },
      body: JSON.stringify({
        model: model,
        messages: [
          { role: "system", content: "你是一个专业的 Git 提交信息生成助手。请根据代码变更生成简洁、清晰的中文提交信息。规范要求：第一行为简短标题（不超过50字符），必须使用 Conventional Commits 前缀（feat, fix, docs, style, refactor, test, chore等），不要带多余的引号和额外解释。如果变更较多，可以分行列出要点。" },
          { role: "user", content: `变更摘要:\n${statusOutput}\n\n变更详情:\n${diff}` }
        ],
        max_tokens: 500,
        temperature: 0.7
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`API 返回错误: ${response.status} ${errorText}`);
    }
    
    const data = await response.json();
    commitMsg = data.choices[0].message.content
      .replace(/^```[a-zA-Z]*\n/g, "")
      .replace(/\n```$/g, "")
      .trim();
  } catch (e) {
    console.warn(`⚠️ AI 生成提交信息失败 (${e.message})，正在使用托底逻辑...`);
    const today = new Date().toLocaleString('zh-CN', { hour12: false });
    commitMsg = `chore: 自动同步代码变更 (${today.split(' ')[0]})\n\n变更摘要：\n${statusOutput}\n\n由于 AI 生成失败，此信息由系统自动生成。`;
  }

  console.log("\n提交信息：");
  console.log("──────────────────────────────────────────────────");
  console.log(commitMsg);
  console.log("──────────────────────────────────────────────────\n");

  // 8. 提交
  console.log("💾 正在创建提交...");
  // 使用临时文件来传递复杂的提交信息，避免 shell 转义问题
  const msgFile = path.join(process.cwd(), ".git", "COMMIT_MSG_TMP");
  fs.writeFileSync(msgFile, commitMsg);
  try {
    await $`git commit -F ${msgFile} --no-verify`;
  } finally {
    if (fs.existsSync(msgFile)) fs.unlinkSync(msgFile);
  }

  // 9. 推送
  console.log("🚀 正在推送到远程仓库...");
  
  // 环境变量处理：清理代理以防干扰
  const proxyVars = ["http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY", "all_proxy", "ALL_PROXY"];
  const originalEnv = { ...process.env };
  proxyVars.forEach(v => delete process.env[v]);

  try {
    const branch = (await $`git rev-parse --abbrev-ref HEAD`.text()).trim();
    const remote = (await $`git config branch.${branch}.remote`.text().catch(() => "origin")).trim();
    const hasUpstream = (await $`git config branch.${branch}.merge`.text().catch(() => "")).trim();

    if (!hasUpstream) {
      console.log(`📡 远程仓库: ${remote}, 分支: ${branch} (首次推送)`);
      await $`git push --set-upstream ${remote} ${branch} --no-verify`;
    } else {
      console.log(`📡 远程仓库: ${remote}, 分支: ${branch}`);
      await $`git push --no-verify`;
    }
    console.log("\n✨ 提交并推送成功！");
  } catch (e) {
    console.error(`\n❌ 推送失败: ${e.message}`);
    console.log("本地提交已保留，你可以手动执行 git push --no-verify");
  } finally {
    // 恢复环境变量
    Object.assign(process.env, originalEnv);
  }
}

main().catch(err => {
  console.error("💥 程序发生未捕获异常:", err);
  process.exit(1);
});
