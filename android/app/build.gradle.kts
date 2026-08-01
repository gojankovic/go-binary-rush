import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
val hasReleaseSigning = keyPropertiesFile.exists()
if (hasReleaseSigning) {
    FileInputStream(keyPropertiesFile).use { keyProperties.load(it) }
}

android {
    namespace = "com.jankovic.gobinaryrush"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.jankovic.gobinaryrush"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Release signing is configured only when android/key.properties exists.
            // Debug builds never require the private signing credentials. When the
            // file is absent the release config is left unsigned and an explicit
            // release build is failed fast below rather than silently producing a
            // debug-signed (Play-rejected) artifact.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                null
            }
        }
    }
}

// Fail an explicitly requested release build when signing credentials are missing,
// instead of emitting an unsigned/debug-signed artifact. Debug builds are unaffected.
if (!hasReleaseSigning) {
    gradle.taskGraph.whenReady {
        val buildingRelease = allTasks.any { task ->
            val name = task.name
            name.contains("Release") &&
                (name.startsWith("assemble") ||
                    name.startsWith("bundle") ||
                    name.startsWith("package"))
        }
        if (buildingRelease) {
            throw GradleException(
                "Release build requested but android/key.properties is missing. " +
                    "Provide signing credentials (keyAlias, keyPassword, storeFile, " +
                    "storePassword) to build a release artifact."
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
