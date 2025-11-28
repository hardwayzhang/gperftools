# 解决 "unable to resolve class GradleException" 错误

## 问题描述

在 `build.gradle` 文件中使用 `GradleException` 时，VSCode 报错：
```
unable to resolve class gradle exception
```

## 原因分析

`GradleException` 是 Gradle API 的一部分，位于 `org.gradle.api` 包中。在 Groovy 构建脚本中，需要显式导入或使用完全限定名。

## 解决方案

### 方案 1: 使用完全限定名（推荐，最简单）

将代码中的 `GradleException` 改为完全限定名：

```gradle
// ❌ 错误写法
throw new GradleException('version number must be "major.minor.patch" format')

// ✅ 正确写法
throw new org.gradle.api.GradleException('version number must be "major.minor.patch" format')
```

### 方案 2: 在文件顶部添加 import 语句

在 `build.gradle` 文件的最顶部添加 import：

```gradle
import org.gradle.api.GradleException

// 然后就可以直接使用
throw new GradleException('version number must be "major.minor.patch" format')
```

### 方案 3: 导入整个 org.gradle.api 包（不推荐）

```gradle
import org.gradle.api.*

throw new GradleException('version number must be "major.minor.patch" format')
```

## 完整示例

### 示例 1: 版本验证

```gradle
// build.gradle
import org.gradle.api.GradleException

def validateVersion(String version) {
    if (!version.matches(/^\d+\.\d+\.\d+$/)) {
        throw new GradleException('version number must be "major.minor.patch" format')
    }
}

version = project.hasProperty('version') ? project.version : '1.0.0'
validateVersion(version)
```

### 示例 2: 条件检查

```gradle
// build.gradle
import org.gradle.api.GradleException

// 检查必需属性
if (!project.hasProperty('requiredProperty')) {
    throw new GradleException('requiredProperty must be set in gradle.properties')
}

// 检查 Java 版本
if (JavaVersion.current() < JavaVersion.VERSION_11) {
    throw new GradleException('Java 11 or higher is required')
}
```

### 示例 3: 使用完全限定名（无需 import）

```gradle
// build.gradle（无需 import）

def validateVersion(String version) {
    if (!version.matches(/^\d+\.\d+\.\d+$/)) {
        throw new org.gradle.api.GradleException('version number must be "major.minor.patch" format')
    }
}

version = project.hasProperty('version') ? project.version : '1.0.0'
validateVersion(version)
```

## VSCode 配置优化

为了让 VSCode 更好地识别 Gradle API，可以在 `.vscode/settings.json` 中添加：

```json
{
  "java.configuration.runtimes": [],
  "java.import.gradle.enabled": true,
  "java.import.gradle.wrapper.enabled": true,
  
  // 让 VSCode 识别 Gradle DSL
  "files.associations": {
    "build.gradle": "groovy",
    "settings.gradle": "groovy"
  }
}
```

## 其他常见的 Gradle API 类

如果需要使用其他 Gradle API 类，也需要导入：

```gradle
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.tasks.TaskExecutionException
import org.gradle.api.InvalidUserDataException

// 使用示例
throw new InvalidUserDataException('Invalid user data provided')
```

## 验证修复

修复后，可以通过以下方式验证：

1. **VSCode 错误消失**：红色波浪线应该消失
2. **运行 Gradle 任务**：
   ```bash
   ./gradlew tasks
   ```
3. **触发错误条件**：如果代码逻辑正确，触发错误条件时应该看到正确的错误消息

## 常见问题

### Q: 为什么 Gradle 运行时没问题，但 VSCode 报错？

A: Gradle 运行时会自动加载 API，但 VSCode 的静态分析需要显式导入。使用完全限定名或 import 语句可以解决。

### Q: 使用 `Exception` 代替 `GradleException` 可以吗？

A: 可以，但不推荐。`GradleException` 提供更好的错误格式化和集成。

```gradle
// 可以工作，但不推荐
throw new Exception('version number must be "major.minor.patch" format')

// 推荐
throw new org.gradle.api.GradleException('version number must be "major.minor.patch" format')
```

### Q: 在 Kotlin DSL (build.gradle.kts) 中如何解决？

A: Kotlin DSL 中可以直接使用，因为 Kotlin 有更好的类型推断：

```kotlin
// build.gradle.kts
import org.gradle.api.GradleException

// 或者直接使用
throw GradleException("version number must be \"major.minor.patch\" format")
```

## 快速修复步骤

1. **找到报错的行**：在 `build.gradle` 中找到使用 `GradleException` 的地方
2. **选择修复方式**：
   - 方式 A：在文件顶部添加 `import org.gradle.api.GradleException`
   - 方式 B：将 `GradleException` 改为 `org.gradle.api.GradleException`
3. **保存文件**：VSCode 会自动重新分析
4. **验证**：错误提示应该消失
