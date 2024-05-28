#!/bin/bash

# Check if the arguments are provided - 1st argument = static dir, 2nd argument - module directory
if [ ! -z "$2" ]; then
    cd "$2" || { echo "Unable to navigate to $"; exit 1; }
fi

# Check if src directory exists
if [ ! -d "src" ]; then
    echo "'src' directory not found in $2"
    exit 1
fi

# Find the directory containing the model directory
BASE_DIR=$(find src -type d -name "model" -printf "%h\n" | head -n 1)

# Check if model directory is found
if [ -z "$BASE_DIR" ]; then
    echo "'model' directory not found in 'src'"
    exit 1
fi

# Set the source directory for models
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
STATIC_FILES_DIR="$SCRIPT_DIR/static/main"


# Function to generate exception package and exceptions---------------------------------------------------------------------------------------------------------
generate_exceptions_package(){
    local EXCEPTION_DIR="$BASE_DIR/exception"
    mkdir -p "$EXCEPTION_DIR"
    package_name=$(realpath "${EXCEPTION_DIR}" | sed 's|.*java/||; s|/|.|g')
    
    # Generate ExceptionPayload class
    echo "package $package_name;" > "$EXCEPTION_DIR/ExceptionPayload.java"
    cat $STATIC_FILES_DIR/exception/ExceptionPayload >> "$EXCEPTION_DIR/ExceptionPayload.java"

    # Generate EntityNotFoundException class
    echo "package $package_name;" > "$EXCEPTION_DIR/EntityNotFoundException.java"
    cat $STATIC_FILES_DIR/exception/EntityNotFoundException >> "$EXCEPTION_DIR/EntityNotFoundException.java"

    # Generate GlobalExceptionHandler class
    echo "package $package_name;" > "$EXCEPTION_DIR/GlobalExceptionHandler.java"
    cat $STATIC_FILES_DIR/exception/GlobalExceptionHandler >> "$EXCEPTION_DIR/GlobalExceptionHandler.java"
}
generate_exceptions_package