# MIT License

# Copyright (c) 2024 Maksym Makhrevych

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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

# Function to generate DTO Requests---------------------------------------------------------------------------------------------------------
generate_reqest_dto() {
    TARGET_DIR="$BASE_DIR/dto/request"
    local model_file="$1"
    local request_type="DtoRequest"
    local model_name=$(basename "$model_file" .java)
    if [[ $model_name == *Model ]]; then
        model_name="${model_name%Model}"
    fi

    local lowercase_model_name=$(echo "$model_name" | tr '[:upper:]' '[:lower:]')
    local dto_dir="$TARGET_DIR"
    mkdir -p "$dto_dir"
    create_request_file="$dto_dir/${model_name}${request_type}.java"

    # Extract package name from the DTO directory structure
    package_name=$(dirname "${create_request_file}" | sed 's|.*java/||; s|/|.|g')

    # Add imports
    echo "package $package_name;" > "$create_request_file"
    echo "" >> "$create_request_file"
    echo "import jakarta.validation.constraints.NotBlank;" >> "$create_request_file"
    echo "import jakarta.validation.constraints.NotNull;" >> "$create_request_file"
    echo "import jakarta.validation.constraints.Positive;" >> "$create_request_file"
    echo "import lombok.Data;" >> "$create_request_file"
    echo "import lombok.AllArgsConstructor;" >> "$create_request_file"
    echo "import lombok.NoArgsConstructor;" >> "$create_request_file"
    echo "" >> "$create_request_file"

    if grep -q "BigDecimal" "$model_file"; then
        echo "import java.math.BigDecimal;" >> "$create_request_file"
    fi
    if grep -q " Date " "$model_file"; then
        echo "import java.util.Date;" >> "$create_request_file"
    fi
    echo "" >> "$create_request_file"

    # Generate CreateRequest class
    echo "@AllArgsConstructor" >> "$create_request_file"
    echo "@NoArgsConstructor" >> "$create_request_file"
    echo "@Data" >> "$create_request_file"
    echo "public class $(basename "$create_request_file" .java) {" >> "$create_request_file"

    # Extract fields from the original model class, excluding id field and LocalDateTime type
    fields=$(grep -E 'private .*;' "$model_file" | sed 's/private \([^ ]*\) \([^;]*\);/\1 \2/' | grep -v "id" | grep -v "LocalDateTime")

    # Iterate over fields
    while IFS= read -r field; do
        # Extract field type and name
        field_type=$(echo "$field" | awk '{print $1}')
        field_name=$(echo "$field" | awk '{print (substr($2,1,1)) substr($2,2)}')
        upper_field_name=$(echo "${field_name}" | sed -E 's/(^|[^A-Za-z])[a-z]/\U&/g' | sed -E 's/([A-Z])/ \1/g' | sed -E 's/^[[:space:]]+//')

        case $field_type in
        String|Long|Integer|BigDecimal|Double)
            echo "" >> "$create_request_file" ;;
        *)
            if [[ "$field_type" == *List* || "$field_type" == *Set* || "$field_type" == *Collection* ]]; then
                :
            else 
                echo "" >> "$create_request_file"
                if [[ $field_name == *Model ]]; then
                    field_name="${field_name%Model}"
                fi
                if [ -f "$MODELS_DIR/$field_type.java" ]; then
                    local id_type=$(getIdType "$field_type")
                    if [ -n "$id_type" ]; then
                        field_type="$id_type"
                        field_name="${field_name}Id"
                    else
                        field_type="String"
                    fi
                else
                    field_type="String"
                fi
            fi
            ;;
        esac

        # Check field type and add validation annotations accordingly
        case "$field_type" in
            String)
                echo "    @NotNull(message = \"$upper_field_name cannot be null\")" >> "$create_request_file"
                echo "    @NotBlank(message = \"$upper_field_name cannot be blank\")" >> "$create_request_file"
                ;;
            Long|Integer|BigDecimal|Double)
                echo "    @Positive(message = \"$upper_field_name must be a positive number\")" >> "$create_request_file"
                echo "    @NotNull(message = \"$upper_field_name cannot be null\")" >> "$create_request_file"
                ;;
            *)
                # Leave other types without annotations
                ;;
        esac

        # Add field declaration to the class without indentation and with semicolon
        if [[ "$field_type" == *List* || "$field_type" == *Set* || "$field_type" == *Collection* ]]; then
                :
        else 
            echo "    private ${field_type} ${field_name};" >> "$create_request_file"
        fi
    done <<< "$fields"

    # Close CreateRequest class
    echo "}" >> "$create_request_file"
}

# Function to generate DTO Responses---------------------------------------------------------------------------------------------------------
generate_response_dto() {
    TARGET_DIR="$BASE_DIR/dto/response"
    local model_file="$1"
    local response_type="DtoResponse"
    local model_name=$(basename "$model_file" .java)
    if [[ $model_name == *Model ]]; then
        model_name="${model_name%Model}"
    fi
    local lowercase_model_name=$(echo "$model_name" | tr '[:upper:]' '[:lower:]')
    local dto_dir="$TARGET_DIR"
    mkdir -p "$dto_dir"
    create_response_file="$dto_dir/${model_name}${response_type}.java"

    # Extract package name from the DTO directory structure
    package_name=$(dirname "${create_response_file}" | sed 's|.*java/||; s|/|.|g')

    # Add imports
    echo "package $package_name;" > "$create_response_file"
    echo "" >> "$create_response_file"

    echo "import lombok.Data;" >> "$create_response_file" 
    echo "import lombok.AllArgsConstructor;" >> "$create_response_file"
    echo "import lombok.NoArgsConstructor;" >> "$create_response_file"
    echo "" >> "$create_response_file"

    if grep -q " LocalDateTime " "$model_file"; then
        echo "import java.time.LocalDateTime;" >> "$create_response_file"
    fi
    if grep -q "BigDecimal" "$model_file"; then
        echo "import java.math.BigDecimal;" >> "$create_response_file"
    fi
    echo "" >> "$create_response_file"

    # Generate CreateResponse class
    echo "@AllArgsConstructor" >> "$create_response_file"
    echo "@NoArgsConstructor" >> "$create_response_file"
    echo "@Data" >> "$create_response_file"
    echo "public class $(basename "$create_response_file" .java) {" >> "$create_response_file"

    # Extract fields from the original model class, excluding id field and LocalDateTime type
    fields=$(grep -E 'private .*;' "$model_file" | sed 's/private \([^ ]*\) \([^;]*\);/\1 \2/')

    # Iterate over fields
    while IFS= read -r field; do
        # Extract field type and name
        field_type=$(echo "$field" | awk '{print $1}')
        field_name=$(echo "$field" | awk '{print $2}')

        case $field_type in
        String|Long|Integer|BigDecimal|Double|LocalDateTime)
            if [ $field_type == "LocalDateTime" ] ; then
            if ! sed -n '3p' "$create_response_file" | grep -q "import com.fasterxml.jackson.annotation.JsonFormat;"; then
                sed -i '3i\import com.fasterxml.jackson.annotation.JsonFormat;' "$create_response_file"
            fi
                echo "    @JsonFormat(pattern = \"yyyy-MM-dd'T'HH:mm:ss\")" >> "$create_response_file"
            fi ;;
        *)
            if [[ "$field_type" == *List* || "$field_type" == *Set* || "$field_type" == *Collection* ]]; then
                :
            else 
                if [[ $field_name == *Model ]]; then
                    field_name="${field_name%Model}"
                fi
                if [ -f "$MODELS_DIR/$field_type.java" ]; then
                    if [[ $field_type == *Model ]]; then
                        field_type="${field_type%Model}"
                    fi
                    field_type="${field_type}DtoResponse"
                fi
            fi ;;
        esac

        # Add field declaration to the class without indentation and with semicolon
        if [[ "$field_type" == *List* || "$field_type" == *Set* || "$field_type" == *Collection* ]]; then
            :
        else 
            echo "" >> "$create_response_file"
            echo "    private ${field_type} ${field_name};" >> "$create_response_file"
        fi
    done <<< "$fields"

    # Close CreateRequest class
    echo "}" >> "$create_response_file"
}
# Iterate over all Java files in the models directory
if [ "$GEN_MODEL" = "All Models" ]; then
    for model_file in "$MODELS_DIR"/*.java; do
        generate_reqest_dto "$model_file" "$request_type"
    done
else
    model_file="$MODELS_DIR"/"$GEN_MODEL".java
    generate_reqest_dto "$model_file" "$request_type"
fi



if [ "$GEN_MODEL" = "All Models" ]; then
    for model_file in "$MODELS_DIR"/*.java; do
        generate_response_dto "$model_file" "$response_type"
    done
else
    model_file="$MODELS_DIR"/"$GEN_MODEL".java
    generate_response_dto "$model_file" "$response_type"
fi
echo "DTO Request/Response generated successfully"