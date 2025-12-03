  edit

     Git Worktree 自动同步 .env.local 文件

     问题背景

     用户在使用 git worktree add 创建新 worktree 时，.env.local
     文件不会被自动复制到新的 worktree 中，因为该文件被 .gitignore
     忽略。每次手动复制比较麻烦。

     用户需求:
     - 使用 Git hook 自动复制 .env.local
     - 使用频率：2-3个 worktree，偶尔使用
     - 目标：简化 worktree 创建流程

     当前项目状态:
     - 已使用 Husky 管理 Git hooks
     - 存在 .env.local 文件在多个位置：
       - /apps/web/.env.local
       - /apps/api/.env.local
       - /.env.local (根目录)
     - 已有 .env.example 模板文件

     ---
     解决方案

     方案选择：Shell 脚本 + Git Alias

     核心思路:
     Git 原生不支持 post-worktree-add hook，因此我们将创建：
     1. 一个 Shell 脚本用于同步 .env.local 文件
     2. 一个 Git alias 封装 git worktree add + 自动同步
     3. 一个备用的 npm script 供手动使用

     优点:
     - 无需修改 Git 核心流程
     - 简单可靠，易于维护
     - 支持回退到原生 git worktree 命令
     - 不依赖第三方工具

     ---
     实施步骤

     步骤 1: 创建同步脚本

     文件: scripts/sync-env-to-worktree.sh

     #!/usr/bin/env bash
     set -e

     # 颜色输出
     GREEN='\033[0;32m'
     YELLOW='\033[1;33m'
     RED='\033[0;31m'
     NC='\033[0m' # No Color

     WORKTREE_PATH="$1"

     if [ -z "$WORKTREE_PATH" ]; then
       echo -e "${RED}错误: 请提供 worktree 路径${NC}"
       echo "用法: $0 <worktree-path>"
       exit 1
     fi

     if [ ! -d "$WORKTREE_PATH" ]; then
       echo -e "${RED}错误: Worktree 路径不存在: $WORKTREE_PATH${NC}"
       exit 1
     fi

     # 获取主 worktree 路径 (git rev-parse --show-toplevel 返回当前
     worktree 根目录)
     MAIN_WORKTREE=$(git worktree list | head -n 1 | awk '{print $1}')

     echo -e "${GREEN}🔄 开始同步 .env.local 文件...${NC}"
     echo "主 worktree: $MAIN_WORKTREE"
     echo "目标 worktree: $WORKTREE_PATH"
     echo ""

     # 需要同步的 .env.local 文件路径
     ENV_FILES=(
       ".env.local"
       "apps/web/.env.local"
       "apps/api/.env.local"
     )

     COPIED_COUNT=0
     SKIPPED_COUNT=0

     for env_file in "${ENV_FILES[@]}"; do
       SOURCE="$MAIN_WORKTREE/$env_file"
       DEST="$WORKTREE_PATH/$env_file"

       if [ -f "$SOURCE" ]; then
         # 创建目标目录（如果不存在）
         mkdir -p "$(dirname "$DEST")"

         # 复制文件
         cp "$SOURCE" "$DEST"
         echo -e "  ${GREEN}✓${NC} 已复制: $env_file"
         ((COPIED_COUNT++))
       else
         echo -e "  ${YELLOW}⊘${NC} 跳过（源文件不存在）: $env_file"
         ((SKIPPED_COUNT++))
       fi
     done

     echo ""
     echo -e "${GREEN}✅ 同步完成!${NC}"
     echo "  • 已复制: $COPIED_COUNT 个文件"
     echo "  • 已跳过: $SKIPPED_COUNT 个文件"

     说明:
     - 自动检测主 worktree 位置
     - 支持多个 .env.local 文件同步
     - 彩色输出，清晰易读
     - 错误处理完善

     ---
     步骤 2: 配置 Git Alias（推荐用法）

     在项目根目录的 .git/config 文件中添加：

     [alias]
         wt = "!f() { \
             git worktree add \"$@\" && \
             WORKTREE_PATH=$(echo \"$@\" | awk '{print $NF}') && \
             ./scripts/sync-env-to-worktree.sh \"$WORKTREE_PATH\"; \
         }; f"

     使用方式:
     # 原命令：git worktree add ../wonderland-nexus-feature
     feature-branch
     # 新命令：
     git wt ../wonderland-nexus-feature feature-branch

     优点:
     - 完全自动化，创建 worktree 后立即同步
     - 语法与原生 git worktree add 一致
     - 不影响其他开发者（alias 是本地配置）

     ---
     步骤 3: 添加 NPM Script（备用方案）

     文件: package.json

     在 scripts 部分添加：

     {
       "scripts": {
         "sync-env": "bash scripts/sync-env-to-worktree.sh"
       }
     }

     使用方式:
     # 手动同步到指定 worktree
     yarn sync-env ../wonderland-nexus-feature

     适用场景:
     - 忘记使用 git wt 创建 worktree
     - 主 worktree 的 .env.local 更新后，需要同步到其他 worktree
     - 新团队成员不熟悉 git alias

     ---
     步骤 4: 添加使用文档

     文件: README.md 或创建 docs/git-worktree-guide.md

     ## Git Worktree 使用指南

     ### 创建新 Worktree（自动同步 .env.local）

     推荐使用 `git wt` 命令（会自动同步环境变量文件）：

     \`\`\`bash
     # 创建并自动同步
     git wt ../wonderland-nexus-feature feature-branch
     \`\`\`

     ### 手动同步 .env.local

     如果使用了原生 `git worktree add`，可以手动同步：

     \`\`\`bash
     yarn sync-env ../wonderland-nexus-feature
     \`\`\`

     ### 查看所有 Worktree

     \`\`\`bash
     git worktree list
     \`\`\`

     ### 删除 Worktree

     \`\`\`bash
     git worktree remove ../wonderland-nexus-feature
     \`\`\`

     ---
     关键文件清单

     需要创建的文件

     scripts/sync-env-to-worktree.sh    - 环境变量同步脚本

     需要修改的文件

     .git/config                        - 添加 git alias
     package.json                       - 添加 sync-env script
     README.md 或新建文档                - 添加使用说明

     ---
     使用流程示例

     场景 1: 创建新 worktree 开发新功能

     # 1. 使用 git wt 创建 worktree（自动同步）
     git wt ../wonderland-nexus-like-feature like-feature

     # 输出示例：
     # Preparing worktree (new branch 'like-feature')
     # HEAD is now at c68b19e fix: feedback bug
     # 🔄 开始同步 .env.local 文件...
     # 主 worktree: /Users/guihuajiu/wonderland/wonderland-nexus
     # 目标 worktree: ../wonderland-nexus-like-feature
     #
     #   ✓ 已复制: .env.local
     #   ✓ 已复制: apps/web/.env.local
     #   ✓ 已复制: apps/api/.env.local
     #
     # ✅ 同步完成!
     #   • 已复制: 3 个文件
     #   • 已跳过: 0 个文件

     # 2. 进入新 worktree 开始开发
     cd ../wonderland-nexus-like-feature
     yarn dev

     场景 2: 主 worktree 更新了 .env.local

     # 在主 worktree 修改 .env.local 后，同步到其他 worktree
     yarn sync-env ../wonderland-nexus-like-feature

     场景 3: 忘记使用 git wt

     # 1. 使用原生命令创建了 worktree
     git worktree add ../wonderland-nexus-bugfix bugfix-branch

     # 2. 手动同步
     yarn sync-env ../wonderland-nexus-bugfix

     ---
     验证清单

     脚本创建

     - scripts/sync-env-to-worktree.sh 已创建
     - 脚本已添加执行权限 (chmod +x)
     - 脚本能正确检测主 worktree 路径
     - 脚本能正确复制所有 .env.local 文件

     Git Alias 配置

     - .git/config 已添加 wt alias
     - 测试 git wt 命令能正常工作
     - Worktree 创建后自动触发同步

     NPM Script

     - package.json 已添加 sync-env script
     - yarn sync-env <path> 能正常工作

     文档

     - 已添加使用说明文档
     - 文档包含常见使用场景
     - 文档说明了备用方案

     ---
     总结

     核心价值:
     - ✅ 完全自动化：使用 git wt 即可自动同步
     - ✅ 零手动操作：无需每次复制粘贴
     - ✅ 支持回退：原生 git worktree 命令仍然可用
     - ✅ 团队友好：不影响不使用 worktree 的开发者

     实施时间: 约 10 分钟
     维护成本: 极低（脚本无需修改，除非新增 .env 文件位置）

     推荐工作流:
     1. 日常使用 git wt 创建 worktree（自动同步）
     2. 特殊情况使用 yarn sync-env 手动同步
     3. 定期清理不用的 worktree (git worktree prune)

     下一步:
     4. 创建 scripts/sync-env-to-worktree.sh 脚本
     5. 配置 Git alias
     6. 添加 NPM script
     7. 测试完整流程





     优化需求

     用户希望简化 git wt 命令的使用：

     当前用法（繁琐）:
     git wt ../wonderland-nexus-feat-xxx -b feat-xxx

     期望用法（简洁）:
     git wt feat-xxx

     自动实现的效果:
     - 自动推断路径：../wonderland-nexus-{分支名}
     - 自动创建分支：-b {分支名}
     - 自动同步 .env.local 文件

     ---
     解决方案

     升级 Git Alias 逻辑

     创建一个智能的 git wt 命令，支持两种模式：

     模式 1: 简化模式（新增）

     git wt feat-xxx
     # 等价于：git worktree add ../wonderland-nexus-feat-xxx -b feat-xxx

     逻辑:
     - 如果只有一个参数（分支名）
     - 自动推断 worktree 路径为：../wonderland-nexus-{分支名}
     - 自动添加 -b 参数创建新分支
     - 同步 .env.local 文件

     模式 2: 完整模式（保留兼容）

     git wt ../custom-path -b branch-name
     git wt ../custom-path existing-branch

     逻辑:
     - 如果有多个参数或路径参数
     - 完全透传给 git worktree add
     - 同步 .env.local 文件

     ---
     实施步骤

     步骤 1: 更新 Git Alias

     文件: .git/config

     [alias]
         wt = "!f() { \
             if [ $# -eq 1 ]; then \
                 BRANCH=\"$1\"; \
                 WORKTREE_NAME=$(echo \"$BRANCH\" | tr '/' '-'); \
                 WORKTREE_PATH=\"../wonderland-nexus-$WORKTREE_NAME\"; \
                 git worktree add \"$WORKTREE_PATH\" -b \"$BRANCH\"; \
             else \
                 git worktree add \"$@\"; \
                 WORKTREE_PATH=\"$1\"; \
             fi && \
             ./scripts/sync-env-to-worktree.sh \"$WORKTREE_PATH\"; \
         }; f"

     逻辑说明:
     1. 检测参数数量 (if [ $# -eq 1 ])
       - 单参数 → 简化模式
       - 多参数 → 完整模式
     2. 简化模式:
       - BRANCH="$1" - 获取分支名（可能包含 /）
       - WORKTREE_NAME=$(echo "$BRANCH" | tr '/' '-') - 将 / 转换为 -
       - WORKTREE_PATH="../wonderland-nexus-$WORKTREE_NAME" - 拼接路径
       - git worktree add "$WORKTREE_PATH" -b "$BRANCH" - 创建
     worktree（分支名保持原样）
     3. 完整模式:
       - git worktree add "$@" - 透传所有参数
       - WORKTREE_PATH="$1" - 第一个参数总是路径
     4. 同步环境变量:
       - 无论哪种模式，都执行 sync-env-to-worktree.sh

     关键改进:
     - 使用 tr '/' '-' 命令自动转换分支名中的斜杠
     - Git 分支名保持 / 分隔（利于 GUI 分组）
     - 文件系统路径使用 - 分隔（避免路径问题）

     ---
     使用示例

     场景 1: 开发新功能（使用 / 分隔）

     # 只需输入分支名（使用 / 分隔）
     git wt feat/like-button

     # 自动执行：
     # - Git 分支名: feat/like-button（Git GUI 中显示在 feat 分组下）
     # - Worktree 路径: ../wonderland-nexus-feat-like-button（自动转换 /
     为 -）
     # - 同步 .env.local 文件

     # 输出示例：
     # Preparing worktree (new branch 'feat/like-button')
     # HEAD is now at 3daf802 fix: deploy
     # 🔄 开始同步 .env.local 文件...
     # 主 worktree: /Users/guihuajiu/wonderland/wonderland-nexus
     # 目标 worktree: ../wonderland-nexus-feat-like-button
     #   ✓ 已复制: .env.local
     #   ✓ 已复制: apps/web/.env.local
     #   ✓ 已复制: apps/api/.env.local
     # ✅ 同步完成!

     场景 2: 修复 Bug（使用 / 分隔）

     git wt fix/navbar-bug

     # 自动创建：
     # - Git 分支: fix/navbar-bug
     # - Worktree 路径: ../wonderland-nexus-fix-navbar-bug

     场景 3: 也支持 - 分隔（向后兼容）

     git wt feat-simple-feature

     # 自动创建：
     # - Git 分支: feat-simple-feature
     # - Worktree 路径: ../wonderland-nexus-feat-simple-feature

     场景 4: 自定义路径（完整模式）

     # 保持原有功能，完全兼容
     git wt ~/projects/custom-worktree -b custom-branch
     git wt ../another-path existing-branch

     ---
     分支命名方案对比

     方案对比

     | 方案   | 分支名示例            | Worktree 路径
           | Git GUI 显示 | 文件系统     |
     |------|------------------|--------------------------------------|--
     ----------|----------|
     | - 分隔 | feat-like-button | ../wonderland-nexus-feat-like-button |
      ✅ 平铺列表     | ✅ 简单路径   |
     | / 分隔 | feat/like-button | ../wonderland-nexus-feat-like-button |
      ✅ 分组折叠     | ⚠️ 需转换 / |

     推荐方案：混合方案（Git 用 /，文件系统用 -）

     核心思路：
     - 分支名使用 /：利用 Git GUI 的分组优势
     - Worktree 路径自动转换 / 为 -：避免文件系统路径问题

     示例：
     # 输入（Git 分支名）
     git wt feat/like-button

     # 自动执行：
     # - 分支名：feat/like-button（Git GUI 中显示为 feat 文件夹下的
     like-button）
     # - Worktree
     路径：../wonderland-nexus-feat-like-button（文件系统友好）

     优点：
     - ✅ Git GUI 中分支自动分组（feat/, fix/, docs/ 等）
     - ✅ 文件系统路径简洁，无特殊字符
     - ✅ 符合业界最佳实践（Git Flow, GitHub Flow 都推荐 / 分隔）
     - ✅ 兼容所有操作系统

     命名约定建议

     # Git 分支名（使用 / 分隔）      文件系统路径（自动转换为 -）
     git wt feat/like-button      # →
     ../wonderland-nexus-feat-like-button
     git wt fix/navbar-bug        # → ../wonderland-nexus-fix-navbar-bug
     git wt refactor/api-client   # →
     ../wonderland-nexus-refactor-api-client
     git wt test/integration      # →
     ../wonderland-nexus-test-integration
     git wt docs/git-workflow     # →
     ../wonderland-nexus-docs-git-workflow

     Git GUI 显示效果（如 SourceTree, GitKraken）：
     📁 feat
       ├─ like-button
       └─ share-feature
     📁 fix
       ├─ navbar-bug
       └─ login-error
     📁 refactor
       └─ api-client

     文件系统显示：
     wonderland/
     ├── wonderland-nexus/              (主 worktree)
     ├── wonderland-nexus-feat-like-button/
     ├── wonderland-nexus-fix-navbar-bug/
     └── wonderland-nexus-refactor-api-client/

     ---
     项目路径检测（可选增强）

     如果未来需要支持自动检测项目名称，可以进一步优化：

     # 自动从当前目录名提取项目名
     PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel)")
     WORKTREE_PATH="../$PROJECT_NAME-$BRANCH"

     当前方案: 硬编码 wonderland-nexus（简单可靠）
     增强方案: 动态提取项目名（更通用，但增加复杂度）

     推荐先使用当前方案，如果未来需要在其他项目使用，再升级。

     ---
     验证清单

     Git Alias 更新

     - .git/config 已更新 wt alias
     - 支持单参数简化模式
     - 支持多参数完整模式
     - 两种模式都能正确同步 .env.local

     功能测试

     - git wt feat-test 创建正确路径和分支
     - git wt ../custom-path -b test 保持原有功能
     - .env.local 文件在两种模式下都正确同步

     ---
     总结

     核心改进:
     - ✅ 输入量减少 70%（git wt feat-xxx vs git wt
     ../wonderland-nexus-feat-xxx -b feat-xxx）
     - ✅ 无需重复输入分支名
     - ✅ 无需手动输入项目名
     - ✅ 保持完整模式兼容性

     实施时间: 2 分钟（只需修改 .git/config）
     风险: 无（保留原有功能，向后兼容）

     推荐工作流:
     1. 日常使用简化模式：git wt feat-xxx
     2. 特殊需求使用完整模式：git wt ~/custom-path -b branch
     3. 手动同步备用：yarn sync-env <path>

     下一步:
     4. 更新 .git/config 中的 wt alias
     5. 测试简化模式和完整模式
     6. （可选）添加使用示例到文档


