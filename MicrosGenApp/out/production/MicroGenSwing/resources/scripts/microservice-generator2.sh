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
# Function to generate service implementation class---------------------------------------------------------------------------------------------------------
generate_service_class() {
    local SERVICE_IMPL_DIR="$BASE_DIR/service"
    local model_name="$1"
    local class_name="$1"
    if [ $# -eq 2 ]; then
        model_name="$2"  # Set model_name to second argument
    fi
    
    local lowercase_model_name="${model_name,}"
    local service_impl_file="$SERVICE_IMPL_DIR/${model_name}Service.java"
    package_name=$(dirname "${service_impl_file}" | sed 's|.*java/||; s|/|.|g')

    # Get the type of id
    id_line=$(grep -n "@Id" "$model_file" | head -n 1 | cut -d ":" -f 1)
    private_line=$(awk "NR > $id_line && /private/ {print NR; exit}" "$model_file")
    id_type=$(awk "NR==$private_line" "$model_file" | awk '{print $2}')

    # Add imports for model class and service interface
    echo "package $package_name;" > "$service_impl_file"
    echo "" >> "$service_impl_file"
    echo "import $base_package_name.exception.EntityNotFoundException;" >> "$service_impl_file"
    echo "import $base_package_name.model.$class_name;" >> "$service_impl_file"
    echo "import $base_package_name.repository.${model_name}Repository;" >> "$service_impl_file"
    echo "import lombok.extern.slf4j.Slf4j;" >> "$service_impl_file"
    echo "import org.springframework.data.domain.Page;" >> "$service_impl_file"
    echo "import org.springframework.data.domain.Pageable;" >> "$service_impl_file"
    echo "import org.springframework.stereotype.Service;" >> "$service_impl_file"
    echo "" >> "$service_impl_file"

    # Generate service implementation class
    echo "@Slf4j" >> "$service_impl_file"
    echo "@Service" >> "$service_impl_file"
    echo "public class ${model_name}Service {" >> "$service_impl_file"
    echo "    private final ${model_name}Repository ${lowercase_model_name}Repository;" >> "$service_impl_file"
    echo "" >> "$service_impl_file"
    echo "    public ${model_name}Service(${model_name}Repository ${lowercase_model_name}Repository) {" >> "$service_impl_file"
    echo "        this.${lowercase_model_name}Repository = ${lowercase_model_name}Repository;" >> "$service_impl_file"
    echo "    }" >> "$service_impl_file"
    echo "" >> "$service_impl_file"

    echo "    public $class_name create($class_name $lowercase_model_name) {" >> "$service_impl_file"
    echo "        log.info(\"$class_name create: {}\", $lowercase_model_name);" >> "$service_impl_file"


    # Pattern to match
    pattern="model.set"

    # Flag to track the conditions
    preprevious_line_is_new=false
    previous_line_is_new=false
    previous_line_is_not_empty=false

    foreign_services=
    service=
    # Read the input file line by line
    while IFS= read -r line; do
        # Check if the current line matches the pattern
        if [[ $line == *"$pattern"* ]]; then
            # Extract the object before "(" sign
            object=$(echo "$line" | awk -F"$pattern" '{print $2}' | awk -F'(' '{print $1}')
            # Check the conditions for appending to the output file
            if $previous_line_is_not_empty && $preprevious_line_is_new; then
                service_name="$(echo "${service:0:1}" | tr '[:upper:]' '[:lower:]')${service:1}"
                if [ -n "$foreign_services" ]; then
                    foreign_services="${foreign_services}\n"
                fi
                foreign_services=${foreign_services}"        ${lowercase_model_name}.set$object(${service_name}.getById(${lowercase_model_name}.get$object().getId()));"
                # Temporary file to store modified content
                temp_file=$(mktemp)
                # Flag to track whether we've encountered 'public' keyword
                public_encountered=false

                # Flag to track whether we're inside the class definition
                inside_class=false
                # Read the file line by line
                while IFS= read -r line; do
                    change_line=false
                    # Check if we've encountered the class definition
                    if [[ $line == *"public class"* ]]; then
                        inside_class=true
                    fi
                    
                    # If we're inside the class definition
                    if $inside_class; then
                        # If we encounter an empty line
                        if [[ -z "${line// }" ]]; then
                            # Add new line
                            echo "    private final $service $service_name;" >> "$temp_file"
                        fi
                        
                        # If we encounter 'public' keyword
                        if [[ $line == *"public "* ]]; then
                            # Set the flag to true
                            public_encountered=true
                        fi
                        
                        # If we've encountered 'public' and '('
                        if $public_encountered && [[ $line == *"("* ]]; then
                            before=$(echo "$line" | awk -F'(' '{print $1}')
                            after=$(echo "$line" | awk -F'(' '{print $2}')

                            # Add the line with '$service $service_name,'
                            echo "$before($service $service_name, $after" >> "$temp_file"
                            echo "        this.$service_name = $service_name;" >> "$temp_file"
                            # Reset the flags
                            public_encountered=false
                            inside_class=false
                            change_line=true
                        fi
                    fi
                    
                    # Write the original line to the temporary file
                    if ! $change_line; then
                        echo "$line" >> "$temp_file"
                    fi
                    
                done < "$service_impl_file"

                # Move the temporary file to the original file
                mv "$temp_file" "$service_impl_file"

            fi
        fi
        
        # Update the flags for the next iteration
        preprevious_line_is_new=$previous_line_is_new
        previous_line_is_not_empty=true
        
        # Check if the current line is not empty
        if [[ -z "${line// }" ]]; then
            previous_line_is_not_empty=false
        fi
        
        # Check if the current line contains '= new'
        if [[ $line == *"= new"* ]]; then
            service=$(echo "$line" | awk -F'        ' '{print $2}' | awk -F' ' '{print $1}')
            if [[ $service == *Model ]]; then
                service="${service%Model}"
            fi
            service="${service}Service"
            previous_line_is_new=true
        else
            previous_line_is_new=false
        fi
    done < "$BASE_DIR/dto/mapper/${model_name}DtoMapper.java"
    echo -e "$foreign_services" >> "$service_impl_file"
    echo "        return ${lowercase_model_name}Repository.save($lowercase_model_name);" >> "$service_impl_file"
    echo "    }" >> "$service_impl_file"
    echo "" >> "$service_impl_file"

    echo "    public $class_name getById($id_type id) {" >> "$service_impl_file"
    echo "        log.info(\"$class_name get by id: {}\", id);" >> "$service_impl_file"
    echo "        return ${lowercase_model_name}Repository.findById(id).orElseThrow(()->new EntityNotFoundException(\"${model_name} with id: \" + id + \" does not exist\"));" >> "$service_impl_file"
    echo "    }" >> "$service_impl_file"
    echo "" >> "$service_impl_file"

    echo "    public Page<$class_name> getAll(Pageable pageable) {" >> "$service_impl_file"
    echo "        log.info(\"$class_name get all: {}\", pageable);" >> "$service_impl_file"
    echo "        return ${lowercase_model_name}Repository.findAll(pageable);" >> "$service_impl_file"
    echo "    }" >> "$service_impl_file"
    echo "" >> "$service_impl_file"

    echo "    public $class_name updateById($id_type id, $class_name $lowercase_model_name) {" >> "$service_impl_file"
    echo "        getById(id);" >> "$service_impl_file"
    echo "        $lowercase_model_name.setId(id);" >> "$service_impl_file"
    echo -e "$foreign_services" >> "$service_impl_file"
    echo "        log.info(\"$class_name update by id: {}\", $lowercase_model_name);" >> "$service_impl_file"
    echo "        return ${lowercase_model_name}Repository.save($lowercase_model_name);" >> "$service_impl_file"
    echo "    }" >> "$service_impl_file"
    echo "" >> "$service_impl_file"

    echo "    public Boolean deleteById($id_type id) {" >> "$service_impl_file"
    echo "        log.info(\"$class_name delete by id: {}\", id);" >> "$service_impl_file"   
    echo "        ${lowercase_model_name}Repository.deleteById(id);" >> "$service_impl_file"
    echo "        return true;" >> "$service_impl_file"
    echo "    }" >> "$service_impl_file"
    echo "}" >> "$service_impl_file"
}

mkdir -p "$BASE_DIR"/service

# Iterate over all Java files in the models directory
if [ "$GEN_MODEL" = "All Models" ]; then
    for model_file in "$MODELS_DIR"/*.java; do
        model_name=$(basename "$model_file" .java)
        if [[ $model_name == *Model ]]; then
            model_name_without_suffix="${model_name%Model}"
            generate_service_class "$model_name" "$model_name_without_suffix"
        else
            generate_service_class "$model_name"
        fi
    done
else
    model_file="$MODELS_DIR"/"$GEN_MODEL".java
    model_name=$GEN_MODEL
    if [[ $model_name == *Model ]]; then
        model_name_without_suffix="${model_name%Model}"
        generate_service_class "$model_name" "$model_name_without_suffix"
    else
        generate_service_class "$model_name"
    fi
fi

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

echo "Microservice generated successfully"