# VSCode 多模块 Gradle 项目配置指南

## 概述

当 VSCode 工作区中有多个 `build.gradle` 文件时（多模块 Gradle 项目），需要正确配置才能让 VSCode 识别和编译所有模块。

## 配置步骤

### 1. 项目结构

多模块 Gradle 项目的典型结构：

```
workspace/
├── settings.gradle          # 根配置文件，定义所有模块
├── build.gradle             # 根项目构建文件
├── gradle/
│   └── wrapper/
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties
├── module1/
│   └── build.gradle         # 模块1的构建文件
├── module2/
│   └── build.gradle         # 模块2的构建文件
└── module3/
    └── build.gradle         # 模块3的构建文件
```

### 2. settings.gradle 配置

在项目根目录创建或编辑 `settings.gradle` 文件，包含所有模块：

```gradle
rootProject.name = 'my-project'

include 'module1'
include 'module2'
include 'module3'

// 如果模块在子目录中
project(':module1').projectDir = file('subdir/module1')
```

### 3. 根 build.gradle 配置

在根目录的 `build.gradle` 中配置所有子模块的通用设置：

```gradle
allprojects {
    repositories {
        mavenCentral()
        // 其他仓库...
    }
}

subprojects {
    apply plugin: 'java'
    
    // 通用配置
    sourceCompatibility = '1.8'
    targetCompatibility = '1.8'
}
```

### 4. VSCode 配置

已创建的 `.vscode/settings.json` 包含以下关键配置：

- `java.import.gradle.enabled: true` - 启用 Gradle 导入
- `java.configuration.updateBuildConfiguration: "automatic"` - 自动更新构建配置

### 5. 必需的 VSCode 扩展

确保安装以下扩展：

1. **Extension Pack for Java** (Microsoft)
   - 包含 Java 语言支持、Gradle 支持等

2. **Gradle for Java** (Microsoft)
   - 提供 Gradle 任务运行和调试支持

### 6. 识别多个独立项目

如果工作区中有多个**独立的** Gradle 项目（不是多模块项目），VSCode 会自动识别它们。每个项目应该有：

- 自己的 `settings.gradle` 或 `build.gradle`
- 自己的 `gradle` 目录（如果使用 wrapper）

### 7. 编译和运行

#### 方法 1: 使用 VSCode 命令面板

1. 按 `Ctrl+Shift+P` (Windows/Linux) 或 `Cmd+Shift+P` (Mac)
2. 输入 "Java: Clean Java Language Server Workspace"
3. 重新加载窗口
4. 使用 "Gradle: Run Gradle Task" 运行构建任务

#### 方法 2: 使用终端

```bash
# 在项目根目录
./gradlew build          # 构建所有模块
./gradlew :module1:build # 构建特定模块
./gradlew tasks          # 查看所有可用任务
```

#### 方法 3: 使用 Gradle 视图

1. 打开 VSCode 侧边栏的 "Java Projects" 视图
2. 展开项目树，可以看到所有模块
3. 右键点击模块或任务来运行

### 8. 常见问题排查

#### 问题 1: VSCode 无法识别模块

**解决方案：**
- 检查 `settings.gradle` 是否正确包含所有模块
- 运行 `./gradlew tasks` 确认 Gradle 能识别所有模块
- 清理并重新导入：`Ctrl+Shift+P` → "Java: Clean Java Language Server Workspace"

#### 问题 2: 编译错误

**解决方案：**
- 检查模块间的依赖关系是否正确配置
- 在 `build.gradle` 中使用 `dependencies { implementation project(':module1') }`
- 确保所有模块的 `build.gradle` 语法正确

#### 问题 3: 无法找到类或包

**解决方案：**
- 确保模块依赖在 `build.gradle` 中正确声明
- 运行 `./gradlew build --refresh-dependencies` 刷新依赖
- 检查 `sourceSets` 配置是否正确

### 9. 示例配置

#### 示例 settings.gradle

```gradle
rootProject.name = 'multi-module-project'

include 'api'
include 'core'
include 'web'

project(':api').projectDir = file('modules/api')
project(':core').projectDir = file('modules/core')
project(':web').projectDir = file('modules/web')
```

#### 示例根 build.gradle

```gradle
plugins {
    id 'java'
}

allprojects {
    group = 'com.example'
    version = '1.0.0'
    
    repositories {
        mavenCentral()
    }
}

subprojects {
    apply plugin: 'java'
    
    dependencies {
        testImplementation 'junit:junit:4.13.2'
    }
}
```

#### 示例模块 build.gradle

```gradle
dependencies {
    // 依赖其他模块
    implementation project(':core')
    implementation project(':api')
    
    // 外部依赖
    implementation 'com.google.guava:guava:31.1-jre'
}
```

## 验证配置

运行以下命令验证配置：

```bash
# 查看所有项目
./gradlew projects

# 查看所有任务
./gradlew tasks --all

# 构建所有模块
./gradlew build
```

如果所有命令成功执行，说明配置正确。
