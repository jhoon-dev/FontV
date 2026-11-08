allprojects {
    repositories {
        google()
        // The compiler JAR's Maven Central download repeatedly returned HTTP 504
        // on CI. Use Google's Central mirror for this module only; the mirrored
        // 2.3.20 JAR was checked against Central's published checksum.
        maven {
            url = uri("https://maven-central.storage-download.googleapis.com/maven2")
            content {
                includeModule("org.jetbrains.kotlin", "kotlin-compiler-embeddable")
            }
        }
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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
