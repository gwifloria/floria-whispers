
> 一次自动化发布翻车引发的思考（本来是想得瑟的）

## 我做了什么
![[Pasted image 20260121130908.png]]
前阵子给自己的 Chrome 插件搞了个自动化发布，告别手动打包上传。设计很简单：

```mermaid
flowchart LR
    A[手动触发<br/>bump-version] -->|创建 tag| B[自动触发<br/>release]
    B -->|构建 + 上传| C[Chrome Web Store]
```

- **bump-version**：手动触发，选版本类型，自动更新版本号并创建 tag
- **release**：监听 tag，执行构建、检查、上传
![[Pasted image 20260121121106.png]]
美滋滋，从此一键发布。

## 翻车现场

结果没几天，有小伙伴反馈：装了插件后没法登录滴答清单。

一番排查后真相大白：

- 第一次发布是我本地手动打包的，本地 `.env.local` 有滴答清单的 API 凭证，一切正常
- 第二次是 GitHub Actions 自动打包，但我压根没把这些凭证配到 GitHub Secrets 里

于是自动发布的版本就成了"阉割版"——构建成功，但运行时无法调用 API。

更尴尬的是，自动发布成功后我偷懒没重新下载测试，直到用户反馈才发现问题 hhh

## 问题根因

这个坑的本质是：**本地环境和 CI 环境的隐性差异**。

本地开发时，我们习惯把敏感信息放在 `.env.local`，这个文件在 `.gitignore` 里，不会提交到仓库。本地构建时 Vite 会读取这些变量，一切正常。

但 GitHub Actions 运行在一个全新的环境里，它：
- 拉取的是仓库代码，没有你的 `.env.local`
- 环境变量需要通过 Secrets 手动配置
- **关键问题**：Vite 构建时如果环境变量不存在，不会报错，只会用 `undefined` 替代

所以构建会"成功"，lint 和 typecheck 也能过，但打包出来的代码里 `import.meta.env.VITE_XXX` 全是 `undefined`。

## 如何避免

### 1. CI 构建前验证环境变量

在 workflow 里加一步检查，缺变量直接失败：
这样忘记配 Secrets 时，workflow 会在构建前就失败并明确提示。

![[Pasted image 20260121123258.png]]

### 2. 自动发布后抽检验证

别完全信任自动化。发布后至少：
- 从 Chrome Web Store 下载安装一次
- 跑一遍核心功能

### 3. 列个 Secrets 清单

在项目 README 或 CLAUDE.md 里记录需要配置哪些 Secrets，新环境部署时对照检查。

## 经验总结

- **本地能跑 ≠ CI 能跑**，环境变量是最容易被遗漏的差异点
- **构建成功 ≠ 功能正常**，Vite 对缺失的环境变量太宽容了
- **自动化需要兜底**，关键变量加验证，发布后要抽检

---

## 附：自动化发布配置要点

如果你也想给 Chrome 扩展搞自动发布，核心步骤：

1. **注册 Chrome Web Store 开发者账号**（$5 一次性费用）
2. **创建 OAuth 凭证**：在 Google Cloud Console 启用 Chrome Web Store API，创建 OAuth 2.0 凭证
3. **获取 Refresh Token**：用 [chrome-webstore-upload-cli](https://github.com/fregante/chrome-webstore-upload-cli) 的交互命令获取
4. **配置 GitHub Secrets**：

| Secret              | 说明                  |
| ------------------- | ------------------- |
| `EXTENSION_ID`      | 扩展 ID               |
| `CWS_CLIENT_ID`     | OAuth Client ID     |
| `CWS_CLIENT_SECRET` | OAuth Client Secret |
| `CWS_REFRESH_TOKEN` | OAuth Refresh Token |
| `VITE_XXX`          | 你的应用需要的环境变量         |

![[Pasted image 20260121121554.png]]

5. **Workflow 设计**：推荐 tag 驱动（见文章开头的流程图）

完整配置参考：[First Glance workflows](https://github.com/gwifloria/first-glance/tree/main/.github/workflows)

## 相关资源

- [chrome-webstore-upload-cli](https://github.com/fregante/chrome-webstore-upload-cli) - 命令行上传工具
- [Chrome Web Store API 文档](https://developer.chrome.com/docs/webstore/api)
- [滴答清单 API 文档](https://developer.dida365.com/docs#/openapi)
