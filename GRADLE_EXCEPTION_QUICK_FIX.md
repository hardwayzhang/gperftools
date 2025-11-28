# GradleException 错误快速修复

## 🚨 错误信息
```
unable to resolve class gradle exception
```

## ✅ 快速修复（两种方法任选其一）

### 方法 1: 添加 import（推荐）

在 `build.gradle` 文件**最顶部**添加：

```gradle
import org.gradle.api.GradleException
```

### 方法 2: 使用完全限定名

将代码中的：
```gradle
throw new GradleException('...')
```

改为：
```gradle
throw new org.gradle.api.GradleException('...')
```

## 📝 完整示例

### 修复前（会报错）
```gradle
def validateVersion(String version) {
    if (!version.matches(/^\d+\.\d+\.\d+$/)) {
        throw new GradleException('version number must be "major.minor.patch" format')
    }
}
```

### 修复后（方法 1 - 添加 import）
```gradle
import org.gradle.api.GradleException

def validateVersion(String version) {
    if (!version.matches(/^\d+\.\d+\.\d+$/)) {
        throw new GradleException('version number must be "major.minor.patch" format')
    }
}
```

### 修复后（方法 2 - 完全限定名）
```gradle
def validateVersion(String version) {
    if (!version.matches(/^\d+\.\d+\.\d+$/)) {
        throw new org.gradle.api.GradleException('version number must be "major.minor.patch" format')
    }
}
```

## 🔍 为什么会出现这个错误？

- Gradle 运行时能识别 `GradleException`（因为自动加载了 API）
- 但 VSCode 的静态分析需要显式导入才能识别
- 添加 import 或使用完全限定名可以让 VSCode 正确识别

## ✨ 修复后

保存文件后，VSCode 的错误提示应该立即消失！
