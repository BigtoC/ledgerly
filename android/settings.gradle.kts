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
    id("com.android.application") version "9.3.3" apply false
    // Pins the Kotlin compiler to 2.4.21. With AGP 9 and
    // android.builtInKotlin=true, AGP compiles Kotlin itself (Built-in
    // Kotlin) with whichever kotlin-gradle-plugin is on the build classpath.
    // AGP 9 only brings in 2.2.10 and the Flutter Gradle Plugin only 2.0.0,
    // so declaring the plugin here, with `apply false`, is what moves the
    // compiler to 2.4.21. It is not applied in app/build.gradle.kts: Built-in
    // Kotlin replaces the kotlin-android plugin there, and AGP 9 rejects it.
    // KGP 2.4.21 is the newest release whose documented ranges cover both
    // Gradle 9.7.0 and AGP 9.3.1 (kotlinlang.org KGP compatibility table).
    // The build uses the 9.7.1 / 9.3.3 patch releases, which are above those
    // maxima (one Gradle patch, two AGP patches), on purpose (see
    // docs/architecture/dependencies.md).
    id("org.jetbrains.kotlin.android") version "2.4.21" apply false
}

include(":app")
