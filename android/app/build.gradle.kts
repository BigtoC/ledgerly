import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    // Kotlin support comes from Built-in Kotlin (android.builtInKotlin=true in
    // gradle.properties), so we no longer apply org.jetbrains.kotlin.android.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

val hasReleaseSigningConfig =
    keystorePropertiesFile.exists() &&
        listOf("keyAlias", "keyPassword", "storeFile", "storePassword").all {
            !keystoreProperties.getProperty(it).isNullOrBlank()
        }
val isReleaseTaskRequested =
    gradle.startParameter.taskNames.any { it.lowercase().contains("release") }

android {
    namespace = "com.example.ledgerly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.ledgerly"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            if (isReleaseTaskRequested && !hasReleaseSigningConfig) {
                throw GradleException(
                    "Release builds require android/key.properties with keyAlias, keyPassword, storeFile, and storePassword.",
                )
            }
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
