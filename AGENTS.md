# AGENTS.md

## 本地构建与验收

- 改完代码后，优先在本地执行 `swift build` 验证编译，不必每次都先提交到 GitHub 等 workflow 跑完。
- 不要用 `swift run AeroSpaceApp` / `swift run NiriSpace` 当作普通验证命令：它会启动常驻 App，看起来像命令卡死。
- 如需验证 App 二进制参数解析或基础启动入口，使用非阻塞命令：
  - `swift run AeroSpaceApp -- --help`
  - `swift run AeroSpaceApp -- --version`
- 验收实际窗口行为时，让用户启动构建出的 `.app` 或现有安装包，并明确告知要测试的快捷键/场景。

## Niri 模式验收提示

- 修改 niri 布局后，至少检查：
  - 单窗口 workspace 是否居中。
  - 多窗口 workspace 左右 focus 是否平滑且不会闪烁。
  - 从单窗口 workspace 切到多窗口 workspace 是否不再闪屏。
  - `alt-c` / `niri-center` 是否能显式居中当前列。
  - `balance-sizes` 在 niri 下是否能把所有列宽重置为 `niri-default-column-width-percent`。
