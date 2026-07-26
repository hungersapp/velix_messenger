allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// file_picker 11.0.2 skips org.jetbrains.kotlin.android when AGP >= 9, assuming
// AGP built-in Kotlin. Flutter keeps android.builtInKotlin=false for plugin
// compatibility, so file_picker's Kotlin sources never compile and
// GeneratedPluginRegistrant cannot resolve FilePickerPlugin.
// Upstream fix: https://github.com/miguelpruivo/flutter_file_picker/pull/2010
gradle.beforeProject {
    if (name != "file_picker") return@beforeProject

    val builtInKotlinEnabled =
        providers
            .gradleProperty("android.builtInKotlin")
            .map { it.toBoolean() }
            .orElse(true)
            .get()

    if (builtInKotlinEnabled) return@beforeProject

    pluginManager.withPlugin("com.android.library") {
        if (!pluginManager.hasPlugin("org.jetbrains.kotlin.android")) {
            pluginManager.apply("org.jetbrains.kotlin.android")
        }
    }

    afterEvaluate {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
