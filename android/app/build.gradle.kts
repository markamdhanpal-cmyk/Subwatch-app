import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val productionApplicationId = "app.subscriptionkiller"

val releaseSigningProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.exists()) {
        propertiesFile.inputStream().use(::load)
    }
}

fun releaseSigningValue(propertyKey: String, environmentKey: String): String? {
    val propertyValue = releaseSigningProperties
        .getProperty(propertyKey)
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
    val environmentValue = providers
        .environmentVariable(environmentKey)
        .orNull
        ?.trim()
        ?.takeIf { it.isNotEmpty() }

    return propertyValue ?: environmentValue
}

val releaseStoreFilePath = releaseSigningValue(
    propertyKey = "storeFile",
    environmentKey = "SUB_KILLER_UPLOAD_STORE_FILE",
)
val releaseStorePassword = releaseSigningValue(
    propertyKey = "storePassword",
    environmentKey = "SUB_KILLER_UPLOAD_STORE_PASSWORD",
)
val releaseKeyAlias = releaseSigningValue(
    propertyKey = "keyAlias",
    environmentKey = "SUB_KILLER_UPLOAD_KEY_ALIAS",
)
val releaseKeyPassword = releaseSigningValue(
    propertyKey = "keyPassword",
    environmentKey = "SUB_KILLER_UPLOAD_KEY_PASSWORD",
)

val isReleaseSigningConfigured = listOf(
    releaseStoreFilePath,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

val isReleaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}

if (isReleaseTaskRequested && !isReleaseSigningConfigured) {
    throw GradleException(
        """
        Release signing is not configured.
        Create android/key.properties or set the SUB_KILLER_UPLOAD_* environment variables:
        - SUB_KILLER_UPLOAD_STORE_FILE
        - SUB_KILLER_UPLOAD_STORE_PASSWORD
        - SUB_KILLER_UPLOAD_KEY_ALIAS
        - SUB_KILLER_UPLOAD_KEY_PASSWORD
        """.trimIndent(),
    )
}

android {
    namespace = productionApplicationId
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
        applicationId = productionApplicationId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (isReleaseSigningConfigured) {
                storeFile = rootProject.file(releaseStoreFilePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
