#!/bin/bash

PROJECT_DIR="$(pwd)"

# Check if build.gradle or build.gradle.kts exists
if [[ ! -f "$PROJECT_DIR/build.gradle" && ! -f "$PROJECT_DIR/build.gradle.kts" ]]; then
    echo "Error: No Gradle project found in $PROJECT_DIR"
    exit 1
fi

# Run the Gradle project
echo "Building the project..."
./gradlew build || { echo "Build failed"; exit 1; }

# Check if a JAR file exists
JAR_FILE=$(find "$PROJECT_DIR/build/libs" -maxdepth 1 -name "*.jar" | head -n 1)

if [[ -f "$JAR_FILE" ]]; then
    echo "Running JAR: $JAR_FILE"
    java -jar "$JAR_FILE"
else
    echo "No JAR file found, attempting to run with 'gradle run'..."
    ./gradlew run || { echo "Run failed"; exit 1; }
fi

