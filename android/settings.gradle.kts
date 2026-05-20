pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    // Pin the Built-in Kotlin classpath to 2.2.20. The Flutter Gradle Plugin
    // bundles kotlin-gradle-plugin:2.0.0 transitively; declaring a newer
    // version here puts it on the classpath so pluginManager.apply(
    // "kotlin-android") inside Flutter's plugin picks up 2.2.20. The plugin
    // is declared with `apply false` and is *not* re-added to
    // app/build.gradle.kts — that keeps the "your app applies KGP"
    // warning suppressed while still satisfying the >=2.2.20 floor.
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
