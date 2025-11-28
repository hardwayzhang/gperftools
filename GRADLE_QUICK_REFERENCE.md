# Gradle 插件快速参考

## 🚀 快速启动编译

### 方法 1: Gradle 视图（最简单）
1. 侧边栏点击 **"Gradle"** 图标
2. 展开项目 → 展开模块 → 展开 `build`
3. **双击 `build`** 任务

### 方法 2: 命令面板
1. `Ctrl+Shift+P` (Windows/Linux) 或 `Cmd+Shift+P` (Mac)
2. 输入：`Gradle: Run Gradle Task`
3. 选择模块和任务

### 方法 3: 终端
```bash
./gradlew build
```

## 📋 识别项目配置

### 查看项目结构
- **Java Projects 视图**：侧边栏 → Java Projects 图标
- **Gradle 视图**：侧边栏 → Gradle 图标

### 验证配置
```bash
./gradlew projects  # 列出所有模块
```

## 🔄 刷新项目

如果修改了 `build.gradle` 或 `settings.gradle`：
- `Ctrl+Shift+P` → `Gradle: Refresh Gradle Project`
- 或右键 Gradle 视图中的项目 → "Refresh"

## 🛠️ 常用任务

| 任务 | 说明 | 位置 |
|------|------|------|
| `build` | 编译所有模块 | Gradle 视图 → build |
| `clean` | 清理构建输出 | Gradle 视图 → build |
| `test` | 运行测试 | Gradle 视图 → verification |
| `jar` | 打包 JAR | Gradle 视图 → build |
| `classes` | 仅编译类文件 | Gradle 视图 → build |

## ⚠️ 故障排除

### 项目未识别？
1. 检查是否安装了 "Gradle for Java" 扩展
2. `Ctrl+Shift+P` → `Java: Clean Java Language Server Workspace`
3. 选择 "Reload and delete"

### 任务列表为空？
- 右键 Gradle 视图中的项目 → "Refresh"

### 编译失败？
- 查看 **Problems 面板** (`Ctrl+Shift+M`)
- 查看终端中的错误信息

## 📍 关键位置

- **Gradle 视图**：侧边栏最下方
- **Java Projects 视图**：侧边栏资源管理器下方
- **Problems 面板**：`View` → `Problems` 或 `Ctrl+Shift+M`
- **输出面板**：`View` → `Output` → 选择 "Gradle"
