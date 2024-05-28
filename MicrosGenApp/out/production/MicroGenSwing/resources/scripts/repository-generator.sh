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

# For imports
base_package_name=$(echo "$BASE_DIR" | sed 's|.*java/||; s|/|.|g')

# Function to generate repository interface---------------------------------------------------------------------------------------------------------
REPOSITORY_DIR="$BASE_DIR/repository"
mkdir -p "$REPOSITORY_DIR"

generate_repository() {
    local model_name="$1"
    local class_name="$1"
    if [ $# -eq 2 ]; then
        model_name="$2"  # Set model_name to second argument
    fi

    local repository_file="$REPOSITORY_DIR/${model_name}Repository.java"
    package_name=$(dirname "${repository_file}" | sed 's|.*java/||; s|/|.|g')

    # Add imports for model and DTO classes
    echo "package $package_name;" > "$repository_file"
    echo "" >> "$repository_file"
    echo "import $base_package_name.model.$class_name;" >> "$repository_file"

    # Get the type of id
    id_line=$(grep -n "@Id" "$model_file" | head -n 1 | cut -d ":" -f 1)
    private_line=$(awk "NR > $id_line && /private/ {print NR; exit}" "$model_file")
    id_type=$(awk "NR==$private_line" "$model_file" | awk '{print $2}')

    # Check if the model class has the @Entity annotation
    if grep -q "@Entity" "$model_file"; then
        repository_extension="JpaRepository<${class_name}, ${id_type}>"
        echo "import org.springframework.data.jpa.repository.JpaRepository;" >> "$repository_file"
    # Check if the model class has the @Document annotation
    elif grep -q "@Document" "$model_file"; then
        repository_extension="MongoRepository<${class_name}, ${id_type}>"
        echo "import org.springframework.data.mongodb.repository.MongoRepository;" >> "$repository_file"
    else
        echo "Error: Model class '$model_name' does not have @Entity or @Document annotation"
        exit 1
    fi

    # Generate repository interface
    echo "" >> "$repository_file"
    echo "public interface ${model_name}Repository extends $repository_extension {" >> "$repository_file"
    echo "" >> "$repository_file"
    echo "}" >> "$repository_file"
}

# Iterate over all Java files in the models directory
if [ "$GEN_MODEL" = "All Models" ]; then
    for model_file in "$MODELS_DIR"/*.java; do
        model_name=$(basename "$model_file" .java)
        if [[ $model_name == *Model ]]; then
            model_name_without_suffix="${model_name%Model}"
            generate_repository "$model_name" "$model_name_without_suffix"
        else
            generate_repository "$model_name"
        fi
    done
else
    model_file="$MODELS_DIR"/"$GEN_MODEL".java
    model_name=$GEN_MODEL
    if [[ $model_name == *Model ]]; then
        model_name_without_suffix="${model_name%Model}"
        generate_repository "$model_name" "$model_name_without_suffix"
    else
        generate_repository "$model_name"
    fi
fi