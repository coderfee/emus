# 发布流程

用户给你这个文档时，直接执行发布，不只说明步骤。

## 版本真源

- 版本以 Xcode 项目为准，不以 Git tag 为准。
- 用 `bash scripts/read-project-version.sh` 读取当前版本。
- `MARKETING_VERSION` 是发布版本，对应 tag 去掉 `v` 后的值。
- `CURRENT_PROJECT_VERSION` 是构建号，每次发布加 `1`。

## 升级规则

- `patch`：修复、重构、CI、文案、本地化、非功能性 UI 调整。
- `minor`：新增用户可见功能、设置项、流程或能力，且兼容旧版本。
- `major`：破坏性变更、移除功能、不兼容配置或数据。

按本次实际发布的改动决定版本，不要把无关脏文件算进去。

## 必做步骤

1. 用 `git status` 和 `git diff` 看清这次要发布的改动。
2. 区分发布范围和无关改动，不要回滚用户的无关修改。
3. 运行 `bash scripts/read-project-version.sh` 读取当前版本。
4. 按改动范围计算新的 `MARKETING_VERSION`。
5. 将 `CURRENT_PROJECT_VERSION` 加 `1`。
6. 修改 `Emus.xcodeproj/project.pbxproj` 中的版本号。
7. 再次运行 `bash scripts/read-project-version.sh`，确认结果正确。
8. 只提交本次发布相关文件。
9. 创建标注标签 `v<MARKETING_VERSION>`。
10. 先推分支，再推 tag。

## 提交规则

- 提交信息使用英文 conventional commit。
- 无关改动分开提交。
- 未经用户明确要求，不要把无关脏文件带进发布。

## 推送规则

- 推送当前分支到 `origin`。
- 用 `git push origin v<MARKETING_VERSION>` 推送 tag。
- 不要 force push。

## 完成前检查

- `bash scripts/read-project-version.sh` 输出的 `MARKETING_VERSION` 正确。
- `bash scripts/read-project-version.sh` 输出的 `CURRENT_PROJECT_VERSION` 已递增。
- `git status --short` 干净，或只剩明确排除的无关改动。
- 本地 tag 已创建，且与新版本一致。

## 说明

- GitHub Actions 会校验 tag 是否与项目版本一致。
- 推送 release tag 后会触发实际发布流程。
