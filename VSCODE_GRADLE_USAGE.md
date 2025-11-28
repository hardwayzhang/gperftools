# VSCode Gradle 插件使用指南

## 一、安装和准备

### 1. 安装必需的扩展

在 VSCode 中安装以下扩展（按 `Ctrl+Shift+X` 打开扩展市场）：

1. **Extension Pack for Java** (Microsoft)
   - 包含 Java 开发所需的所有扩展
   - 包括 Gradle 支持

2. **Gradle for Java** (Microsoft) 
   - 专门用于 Gradle 项目支持

### 2. 验证安装

安装完成后，重启 VSCode。你应该能看到：
- 底部状态栏显示 Java 相关图标
- 侧边栏出现 "Java Projects" 视图

## 二、识别和加载 Gradle 项目

### 方法 1: 自动识别（推荐）

1. **打开项目文件夹**
   - `File` → `Open Folder` → 选择包含 `build.gradle` 或 `settings.gradle` 的根目录

2. **等待自动导入**
   - VSCode 会自动检测 Gradle 项目
   - 右下角会显示 "Java projects are being imported..."
   - 等待导入完成（可能需要几分钟）

3. **查看导入状态**
   - 点击底部状态栏的 Java 图标
   - 或查看输出面板：`View` → `Output` → 选择 "Language Support for Java"

### 方法 2: 手动触发导入

如果自动导入失败，手动触发：

1. 按 `Ctrl+Shift+P` (Windows/Linux) 或 `Cmd+Shift+P` (Mac)
2. 输入并选择：`Java: Clean Java Language Server Workspace`
3. 选择 "Reload and delete"
4. 等待重新导入

### 方法 3: 使用命令面板

1. `Ctrl+Shift+P` → 输入 `Java: Import Gradle Project`
2. 选择项目根目录
3. 等待导入完成

## 三、查看和识别项目结构

### 1. Java Projects 视图

1. **打开视图**
   - 点击侧边栏的 "Java Projects" 图标（或 `View` → `Open View...` → `Java Projects`）

2. **查看项目结构**
   ```
   Java Projects
   ├── 📁 Your Project Name
   │   ├── 📁 Referenced Libraries
   │   ├── 📁 module1
   │   │   ├── 📁 src/main/java
   │   │   └── 📁 src/test/java
   │   ├── 📁 module2
   │   └── 📁 module3
   ```

3. **识别多模块**
   - 每个模块会显示为独立的文件夹
   - 展开可以看到源代码和测试代码

### 2. Gradle Tasks 视图

1. **打开 Gradle 视图**
   - 侧边栏找到 "Gradle" 图标（如果没有，安装 "Gradle for Java" 扩展）
   - 或 `View` → `Open View...` → `Gradle`

2. **查看任务树**
   ```
   Gradle
   ├── 📁 :root-project
   │   ├── 📁 build
   │   ├── 📁 help
   │   └── 📁 verification
   ├── 📁 :module1
   │   ├── 📁 build
   │   ├── 📁 classes
   │   └── 📁 test
   └── 📁 :module2
       └── ...
   ```

## 四、启动编译

### 方法 1: 使用 Gradle 视图（最直观）

1. **打开 Gradle 视图**
   - 侧边栏点击 "Gradle" 图标

2. **运行构建任务**
   - 展开项目 → 展开 `:root-project` → 展开 `build`
   - 双击 `build` 任务，或右键选择 "Run Gradle Task"
   - 这会执行 `./gradlew build`

3. **运行特定模块的构建**
   - 展开 `:module1` → `build` → 双击 `build`
   - 只编译该模块

4. **查看其他常用任务**
   - `clean` - 清理构建输出
   - `test` - 运行测试
   - `jar` - 打包 JAR
   - `classes` - 编译类文件

### 方法 2: 使用命令面板

1. **打开命令面板**
   - `Ctrl+Shift+P` (Windows/Linux) 或 `Cmd+Shift+P` (Mac)

2. **运行 Gradle 任务**
   - 输入：`Gradle: Run Gradle Task`
   - 选择项目（如果有多个）
   - 选择要运行的模块（如 `:root-project`）
   - 选择任务（如 `build`）

3. **常用命令**
   - `Gradle: Run Gradle Task` - 运行任务
   - `Gradle: Refresh Gradle Project` - 刷新项目
   - `Gradle: Run Gradle Wrapper Task` - 使用 wrapper 运行任务

### 方法 3: 使用终端

1. **打开集成终端**
   - `Ctrl+`` (反引号) 或 `View` → `Terminal`

2. **运行 Gradle 命令**
   ```bash
   # 构建所有模块
   ./gradlew build
   
   # 构建特定模块
   ./gradlew :module1:build
   
   # 清理并构建
   ./gradlew clean build
   
   # 运行测试
   ./gradlew test
   
   # 查看所有任务
   ./gradlew tasks
   ```

### 方法 4: 使用快捷键和右键菜单

1. **在文件资源管理器中**
   - 右键点击 `build.gradle` 文件
   - 选择 "Run Gradle Task"
   - 选择要执行的任务

2. **在 Java Projects 视图中**
   - 右键点击模块
   - 选择 "Build" 或 "Clean"

## 五、查看编译结果

### 1. 终端输出

- 编译过程会显示在终端中
- 查看编译错误和警告

### 2. Problems 面板

1. **打开问题面板**
   - `View` → `Problems` 或 `Ctrl+Shift+M`

2. **查看编译错误**
   - 所有编译错误和警告会显示在这里
   - 点击错误可跳转到对应文件

### 3. 输出面板

1. **查看 Gradle 输出**
   - `View` → `Output`
   - 在下拉菜单中选择 "Gradle" 或 "Java"

### 4. 构建输出位置

编译后的文件通常在：
- `build/classes/` - 编译的类文件
- `build/libs/` - 生成的 JAR 文件
- `build/reports/` - 测试报告

## 六、调试和运行

### 1. 运行应用程序

1. **创建运行配置**
   - 打开 `src/main/java` 中的主类
   - 点击类名左侧的运行按钮 ▶️
   - 或按 `F5` 开始调试

2. **使用 launch.json**
   - `.vscode/launch.json` 中配置启动参数

### 2. 运行测试

1. **在代码中**
   - 点击测试方法上方的 "Run Test" 链接
   - 或右键测试方法 → "Run Test"

2. **使用 Gradle 视图**
   - 展开模块 → `verification` → 双击 `test`

## 七、常见操作

### 刷新项目配置

如果修改了 `build.gradle` 或 `settings.gradle`：

1. `Ctrl+Shift+P` → `Gradle: Refresh Gradle Project`
2. 或右键 Gradle 视图中的项目 → "Refresh"

### 清理工作区

如果遇到奇怪的问题：

1. `Ctrl+Shift+P` → `Java: Clean Java Language Server Workspace`
2. 选择 "Reload and delete"
3. 等待重新导入

### 查看项目信息

1. `Ctrl+Shift+P` → `Java: Show Build Job Status`
2. 查看当前构建任务状态

## 八、验证配置是否生效

### 检查清单

- [ ] VSCode 底部状态栏显示 Java 图标
- [ ] 侧边栏能看到 "Java Projects" 视图
- [ ] 侧边栏能看到 "Gradle" 视图
- [ ] Java Projects 视图中能看到所有模块
- [ ] Gradle 视图中能看到任务树
- [ ] 运行 `./gradlew projects` 能列出所有模块
- [ ] 运行 `./gradlew build` 能成功编译

### 快速测试

1. **打开终端** (`Ctrl+``)
2. **运行命令**：
   ```bash
   ./gradlew projects
   ```
3. **应该看到**：
   ```
   Root project 'your-project'
   \--- Project ':module1'
   \--- Project ':module2'
   ...
   ```

## 九、故障排除

### 问题 1: Gradle 视图为空

**解决方案：**
- 确保已安装 "Gradle for Java" 扩展
- 运行 `Gradle: Refresh Gradle Project`
- 检查项目根目录是否有 `build.gradle` 或 `settings.gradle`

### 问题 2: 无法识别模块

**解决方案：**
- 检查 `settings.gradle` 中的 `include` 语句
- 运行 `./gradlew projects` 验证 Gradle 能识别模块
- 清理并重新导入工作区

### 问题 3: 编译失败

**解决方案：**
- 查看 Problems 面板中的错误信息
- 检查终端中的详细错误
- 运行 `./gradlew build --stacktrace` 查看详细堆栈

### 问题 4: 任务列表不完整

**解决方案：**
- 右键 Gradle 视图中的项目 → "Refresh"
- 或运行 `Gradle: Refresh Gradle Project`

## 十、推荐工作流程

1. **打开项目** → VSCode 自动识别
2. **查看结构** → Java Projects 视图确认模块
3. **编写代码** → 自动编译和错误提示
4. **运行构建** → Gradle 视图双击 `build`
5. **查看结果** → Problems 面板和终端
6. **运行测试** → Gradle 视图或代码中的运行按钮
7. **调试应用** → F5 或运行按钮
