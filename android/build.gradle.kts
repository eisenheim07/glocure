allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Force all subprojects to use AGP 8.7.3 to avoid old artifact downloads
    configurations.all {
        resolutionStrategy {
            force("com.android.tools.build:gradle:8.7.3")
        }
    }
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
