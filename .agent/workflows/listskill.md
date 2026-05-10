---
description: 展示当前项目有多少skill可用
---
1. 使用工具或命令在当前项目中全局查找 `SKILL.md` 文件。
// turbo
2. 运行命令 `find . -type f -name "SKILL.md" | grep -v "node_modules"` 来找到所有相关的技能定义文件。
3. 如果没有找到任何文件，则向用户报告当前项目没有可用的技能。
4. 如果找到了 `SKILL.md` 文件，统计其数量。
5. 遍历找到的每一个 `SKILL.md` 文件，读取它的内容并提取 YAML frontmatter 中的 `name` 和 `description` 等信息。
6. 最后，为用户总结出当前项目总共有多少个技能，并以列表形式展示每个技能的名称及其功能简述。
