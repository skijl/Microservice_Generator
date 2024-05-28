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

GEN_MODEL=$1

# Find the directory containing the model directory
BASE_DIR=$(find src -type d -name "model" -printf "%h\n" | head -n 1)

# Check if model directory is found
if [ -z "$BASE_DIR" ]; then
    echo "'model' directory not found in 'src'"
    exit 1
fi

# Set the source directory for models
MODELS_DIR="$BASE_DIR/model"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
STATIC_FILES_DIR="$SCRIPT_DIR/static/main"

# For imports
base_package_name=$(echo "$BASE_DIR" | sed 's|.*java/||; s|/|.|g')

# Function to generate controller class---------------------------------------------------------------------------------------------------------
generate_controller() {
    local model_name="$1"
    local class_name="$1"
    if [ $# -eq 2 ]; then
        model_name="$2"  # Set model_name to second argument
    fi

    # Check if DTOs exist
    dtos_exist=false
    if [ -e "$BASE_DIR/dto/request/${model_name}DtoRequest.java" ] && [ -e "$BASE_DIR/dto/response/${model_name}DtoResponse.java" ] ; then
        dtos_exist=true
    fi
    
    if [ "$dtos_exist" = false ] ; then
        return
    fi

    local lowercase_model_name=$(echo "${model_name:0:1}" | tr '[:upper:]' '[:lower:]')${model_name:1}
    local controller_file="$CONTROLLER_DIR/${model_name}Controller.java"
    local lowercase_controller_name="${model_name}Controller"
    local request_model_name="$(echo "$lowercase_model_name" | sed 's/\([A-Z]\)/-\1/g' | tr '[:upper:]' '[:lower:]')"
    package_name=$(dirname "${controller_file}" | sed 's|.*java/||; s|/|.|g')

    # Get the type of id
    id_line=$(grep -n "@Id" "$model_file" | head -n 1 | cut -d ":" -f 1)
    private_line=$(awk "NR > $id_line && /private/ {print NR; exit}" "$model_file")
    id_type=$(awk "NR==$private_line" "$model_file" | awk '{print $2}')

    # Add imports for model class and service interface
    echo "package ${package_name};" > "$controller_file"
    echo "" >> "$controller_file"

    echo "import $base_package_name.dto.mapper.${model_name}DtoMapper;" >> "$controller_file"
    echo "import $base_package_name.dto.request.${model_name}DtoRequest;" >> "$controller_file"
    echo "import $base_package_name.dto.response.${model_name}DtoResponse;" >> "$controller_file"
    echo "import $base_package_name.model.${class_name};" >> "$controller_file"
    echo "import $base_package_name.service.${model_name}Service;" >> "$controller_file"
    sed "s~\${model_name}~$model_name~g; s~\${lowercase_model_name}~$lowercase_model_name~g; s~\${request_model_name}~$request_model_name~g; s~\${id_type}~$id_type~g; s~\${class_name}~$class_name~g" "$STATIC_FILES_DIR/controller/static1" >> "$controller_file"
}

# Create controller directory if it doesn't exist
CONTROLLER_DIR="$BASE_DIR/controller"
mkdir -p "$CONTROLLER_DIR"

# Iterate over all Java files in the models directory
if [ "$GEN_MODEL" = "All Models" ]; then
    for model_file in "$MODELS_DIR"/*.java; do
        model_name=$(basename "$model_file" .java)
        if [[ $model_name == *Model ]]; then
            model_name_without_suffix="${model_name%Model}"
            generate_controller "$model_name" "$model_name_without_suffix"
        else
            generate_controller "$model_name"
        fi
    done
else
    model_file="$MODELS_DIR"/"$GEN_MODEL".java
    model_name=$GEN_MODEL
    if [[ $model_name == *Model ]]; then
        model_name_without_suffix="${model_name%Model}"
        generate_controller "$model_name" "$model_name_without_suffix"
    else
        generate_controller "$model_name"
    fi
fi