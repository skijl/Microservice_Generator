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

# Get type of Id
getIdType() {
    model_file=$(find "$MODELS_DIR" -maxdepth 1 -type f -name "*.java" -print -quit)
    if [ -n "$model_file" ]; then
        if [ ! -z "$1" ]; then
            model_file="$MODELS_DIR/$1.java"
            id_line=$(grep -n "@Id" "$model_file" | head -n 1 | cut -d ":" -f 1)
            private_line=$(awk "NR > $id_line && /private/ {print NR; exit}" "$model_file")
            id_type=$(awk "NR==$private_line" "$model_file" | awk '{print $2}')
            echo "$id_type"
        else
            id_line=$(grep -n "@Id" "$model_file" | head -n 1 | cut -d ":" -f 1)
            private_line=$(awk "NR > $id_line && /private/ {print NR; exit}" "$model_file")
            id_type=$(awk "NR==$private_line" "$model_file" | awk '{print $2}')
            echo "$id_type"
        fi
    else
        echo "No models are detected in /model dir"
        exit 1
    fi
}

# Function to generate DTO mappers---------------------------------------------------------------------------------------------------------
generate_dto_mapper() {
    local model_name="$1"
    local class_name="$1"
    if [ $# -eq 2 ]; then
        model_name="$2"  # Set model_name to second argument
    fi

    # Define DTO for mapping exist
    request_exists=false
    response_exists=false
    if [ -e "$BASE_DIR/dto/request/${model_name}DtoRequest.java" ]; then
        request_exists=true
    fi
    if [ -e "$BASE_DIR/dto/response/${model_name}DtoResponse.java" ]; then
        response_exists=true
    fi
    if [ "$request_exists" = false ] && [ "$response_exists" = false ]; then
        return
    fi

    # Set the target directory for DTO mappers
    local lowercase_model_name=$(echo "$model_name" | tr '[:upper:]' '[:lower:]')
    local mapper_dir="$BASE_DIR/dto/mapper"
    mkdir -p "$mapper_dir"
    create_mapper_file="$mapper_dir/${model_name}DtoMapper.java"

    # Extract package name from the DTO directory structure
    package_name=$(dirname "${create_mapper_file}" | sed 's|.*java/||; s|/|.|g')

    # Add imports for model and DTO classes
    echo "package $package_name;" > "$create_mapper_file"
    echo "" >> "$create_mapper_file"
    echo "import $base_package_name.model.$class_name;" >> "$create_mapper_file"
    if [ "$request_exists" = true ]; then
        echo "import ${base_package_name}.dto.request.${model_name}DtoRequest;" >> "$create_mapper_file"
    fi
    if [ "$response_exists" = true ]; then
        echo "import ${base_package_name}.dto.response.${model_name}DtoResponse;" >> "$create_mapper_file"
    fi
    echo "" >> "$create_mapper_file"

    echo "public class ${model_name}DtoMapper {" >> "$create_mapper_file"
    echo "" >> "$create_mapper_file"

    # Generate toModel method
    if [ "$request_exists" = true ]; then
        echo "    public static $class_name toModel(${model_name}DtoRequest request) {" >> "$create_mapper_file"
        echo "        $class_name model = new $class_name();" >> "$create_mapper_file"
        echo "" >> "$create_mapper_file"
        # Iterate over fields in the model
        grep -E 'private .*;' "$model_file" | sed 's/private \([^ ]*\) \([^;]*\);/\1 \2/' | while read -r field; do
            field_type=$(echo "$field" | awk '{print $1}')
            field_name=$(echo "$field" | awk '{print $2}')
            full_field_name="$(echo "${field_name:0:1}" | tr '[:lower:]' '[:upper:]')${field_name:1}"
            if [[ $field_name == *Model ]]; then
                field_name="${field_name%Model}"
            fi
            # Check if field exists in CreateRequest and map it
            if grep -q "private .* $field_name;" "$BASE_DIR/dto/request/${model_name}DtoRequest.java"; then
                echo "        model.set${field_name^}(request.get${field_name^}());" >> "$create_mapper_file"
            elif grep -q "private .* ${field_name}Id;" "$BASE_DIR/dto/request/${model_name}DtoRequest.java"; then
                lower_field_type="$(echo "${field_name:0:1}" | tr '[:upper:]' '[:lower:]')${field_name:1}"
                field_name="$(echo "${field_name:0:1}" | tr '[:lower:]' '[:upper:]')${field_name:1}"
                echo "        ${field_type} ${lower_field_type} = new ${field_type}();" >> "$create_mapper_file"
                echo "        ${lower_field_type}.setId(request.get${field_name}Id());" >> "$create_mapper_file"
                echo "        model.set${full_field_name}(${lower_field_type});" >> "$create_mapper_file"
                sed -i "3i\import $base_package_name.model.${field_type};" "$create_mapper_file"
            fi
        done
        echo "" >> "$create_mapper_file"
        echo "        return model;" >> "$create_mapper_file"
        echo "    }" >> "$create_mapper_file"
        echo "" >> "$create_mapper_file"
    fi
    # Generate toResponse method
    if [ "$response_exists" = true ]; then
        echo "    public static ${model_name}DtoResponse toResponse(${class_name} model) {" >> "$create_mapper_file"
        echo "        ${model_name}DtoResponse response = new ${model_name}DtoResponse();" >> "$create_mapper_file"
        echo "" >> "$create_mapper_file"
        # Iterate over fields in the model
        grep -E 'private .*;' "$model_file" | sed 's/private \([^ ]*\) \([^;]*\);/\1 \2/' | while read -r field; do
            field_type=$(echo "$field" | awk '{print $1}')
            field_name=$(echo "$field" | awk '{print $2}')
            # Check if field exists in CreateResponse and map it
            if grep -q "private $field_type $field_name;" "$BASE_DIR/dto/response/${model_name}DtoResponse.java"; then
                echo "        response.set${field_name^}(model.get${field_name^}());" >> "$create_mapper_file"
            else 
                field_type=$(echo "$field" | awk '{print $1}')
                if [[ $field_type == *Model ]]; then
                    field_type="${field_type%Model}"
                fi
                field_name="$(echo "${field_name:0:1}" | tr '[:lower:]' '[:upper:]')${field_name:1}"
                response_field_name=$(grep "private ${field_type}DtoResponse .*;" "$BASE_DIR/dto/response/${model_name}DtoResponse.java" | sed -E 's/private '${field_type}'DtoResponse (.+?);/\1/' | sed -E 's/.{3}//' | sed 's/./\U&/' | sed 's/^.//')
                response_field_name="$(echo "${response_field_name:0:1}" | tr '[:lower:]' '[:upper:]')${response_field_name:1}"
                if grep -q "private ${field_type}DtoResponse .*;" "$BASE_DIR/dto/response/${model_name}DtoResponse.java"; then
                    echo "        response.set${response_field_name}(${field_type}DtoMapper.toResponse(model.get${field_name}()));" >> "$create_mapper_file"
                fi
            fi
        done
        echo "" >> "$create_mapper_file"
        echo "        return response;" >> "$create_mapper_file"
        echo "    }" >> "$create_mapper_file"
        echo "" >> "$create_mapper_file"
    fi

    echo "    private ${model_name}DtoMapper() {}" >> "$create_mapper_file"
    echo "" >> "$create_mapper_file"
    echo "}" >> "$create_mapper_file"
}
if [ "$GEN_MODEL" = "All Models" ]; then
    for model_file in "$MODELS_DIR"/*.java; do
        model_name=$(basename "$model_file" .java)
        if [[ $model_name == *Model ]]; then
            model_name_without_suffix="${model_name%Model}"
            generate_dto_mapper "$model_name" "$model_name_without_suffix"
        else
            generate_dto_mapper "$model_name"
        fi
    done
else
    model_file="$MODELS_DIR"/"$GEN_MODEL".java
    model_name=$GEN_MODEL
    if [[ $model_name == *Model ]]; then
        model_name_without_suffix="${model_name%Model}"
        generate_dto_mapper "$model_name" "$model_name_without_suffix"
    else
        generate_dto_mapper "$model_name"
    fi
fi