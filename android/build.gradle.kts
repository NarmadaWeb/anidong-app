allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Remove corrupted NDK directory to allow automatic re-download
val ndkPath = System.getenv("ANDROID_NDK_HOME") ?: System.getenv("NDK_HOME") ?: "/home/indra/Android/sdk/ndk/27.0.12077973"
val ndkSourceProperties = file("$ndkPath/source.properties")
if (ndkSourceProperties.exists() && !ndkSourceProperties.canRead()) {
    println("Detected corrupted source.properties in NDK directory, deleting to allow re-download.")
    ndkSourceProperties.delete()
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
