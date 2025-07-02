# Flutter 应用打包与优化详细步骤

本文档详细记录了为一个 Flutter 项目设置应用图标、更改应用名称、配置发布 (Release) 版本、缩减应用体积以及分架构打包的全过程。

---

### 一、设置应用图标

我们使用 `flutter_launcher_icons` 工具包来自动生成所有平台所需的图标。

1.  **添加依赖**：将 `flutter_launcher_icons` 添加到 `pubspec.yaml` 的 `dev_dependencies` 中。
    ```shell
    flutter pub add flutter_launcher_icons --dev
    ```

2.  **准备图标文件**：
    *   在项目根目录创建 `assets/icon` 文件夹。
    *   将一个高分辨率（推荐 1024x1024 像素）的应用图标源文件放入该目录，并命名为 `icon.png`。

3.  **配置 `pubspec.yaml`**：在 `pubspec.yaml` 文件中添加以下配置，指定图标路径。
    ```yaml
    flutter_launcher_icons:
      android: "launcher_icon"
      ios: true
      image_path: "assets/icon/icon.png"
    ```

4.  **生成图标**：运行以下命令，工具包会自动在 Android 和 iOS 项目中生成所有尺寸的图标。
    ```shell
    flutter pub run flutter_launcher_icons:main
    ```

---

### 二、更改应用显示名称

应用的显示名称在 Android 的 `AndroidManifest.xml` 文件中定义。

1.  **定位文件**：打开 `android/app/src/main/AndroidManifest.xml`。
2.  **修改标签**：找到 `<application>` 标签，将其中的 `android:label` 属性的值修改为期望的应用名称，例如 "拣货记录"。
    ```xml
    <application
        android:label="拣货记录"
        ...
    >
    ```

---

### 三、配置 Release 版本签名

发布应用需要使用数字证书进行签名。

1.  **生成签名密钥**：
    *   在命令行中，进入 `android/app` 目录。
    *   运行 `keytool` 命令生成一个名为 `upload-keystore.jks` 的密钥库文件。期间会提示您设置密码和填写一些信息。
        ```shell
        cd android/app
        keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
        ```
    *   **注意**：请务必妥善保管此 `jks` 文件和您的密码。

2.  **创建密钥属性文件**：
    *   在 `android` 目录下创建一个名为 `key.properties` 的文件。
    *   在此文件中填入您的密钥信息（**请勿将此文件提交到 Git**）。
        ```properties
        storePassword=YOUR_STORE_PASSWORD
        keyPassword=YOUR_KEY_PASSWORD
        keyAlias=upload
        storeFile=../app/upload-keystore.jks
        ```

3.  **配置 Gradle 使用签名**：修改 `android/app/build.gradle.kts` 文件，让其在构建 Release 版本时读取密钥信息并应用签名。
    *   在文件顶部添加 `import`。
    *   在 `android` 配置块之前添加读取 `key.properties` 的逻辑。
    *   创建 `signingConfigs` 块。
    *   在 `buildTypes.release` 中指定使用该签名配置。

---

### 四、缩减 App 体积与分包

这是优化中最关键的步骤，我们通过代码缩减、资源缩减和按CPU架构分包来显著减小 APK 体积。

1.  **启用代码和资源缩减 (R8)**：
    *   在 `android/app/build.gradle.kts` 的 `buildTypes.release` 部分，启用 `minifyEnabled` 和 `shrinkResources`。

2.  **配置 ProGuard 规则**：
    *   R8 可能会移除一些应用正常运行所必需的代码。我们需要创建规则来防止这种情况。
    *   在 `android/app` 目录下创建一个 `proguard-rules.pro` 文件。
    *   填入 Flutter 官方推荐的保留规则，以及在构建过程中提示缺失的 Play Core 库规则。
    *   在 `build.gradle.kts` 的 `buildTypes.release` 部分，通过 `proguardFiles(...)` 来指定使用的规则文件。

3.  **配置分包 (Splits)**：
    *   为了只支持主流的 ARM 架构并为它们生成独立的 APK，在 `android/app/build.gradle.kts` 的 `android` 配置块中添加 `splits` 配置。
    *   这会为 `armeabi-v7a` (32位) 和 `arm64-v8a` (64位) 分别生成 APK，并自动排除 x86/x86_64 架构。

---

### 五、执行最终构建

由于 `flutter build apk` 命令可能会忽略 `build.gradle` 中的高级配置（如 `splits`），因此**必须直接调用 Gradle 来执行构建**。

1.  **进入 Android 目录**：
    ```shell
    cd android
    ```

2.  **运行 Gradle 命令**：
    ```shell
    ./gradlew assembleRelease
    ```

构建成功后，最终优化过的、按架构拆分的 APK 文件会位于 `build/app/outputs/apk/release/` 目录下。
