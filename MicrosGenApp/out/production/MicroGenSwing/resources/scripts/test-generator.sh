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

GEN_MODEL="$1"

# Find the base dirs
BASE_DIR=$(find src -type d -name "model" -printf "%h\n" | head -n 1)
TEST_BASE_DIR=$(echo "$BASE_DIR" | sed 's/main/test/')
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
STATIC_FILES_TEST_DIR="$SCRIPT_DIR/static/test"

# Check if model directory is found
if [ -z "$BASE_DIR" ]; then
    echo "'model' directory not found in 'src'"
    exit 1
fi

# Set the source directory for models
MODELS_DIR="$BASE_DIR/model"


# For imports
base_package_name=$(echo "$BASE_DIR" | sed 's|.*java/||; s|/|.|g')


mkdir -p "$TEST_BASE_DIR/static_object"

# Function to create Static Object classes-------------------------------------------------------------------------
create_static_object_classes() {
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

    local lowercase_model_name=$(echo "${model_name:0:1}" | tr '[:upper:]' '[:lower:]')${model_name:1}

    # Get the type of id
    id_line=$(grep -n "@Id" "$model_file" | head -n 1 | cut -d ":" -f 1)
    private_line=$(awk "NR > $id_line && /private/ {print NR; exit}" "$model_file")
    id_type=$(awk "NR==$private_line" "$model_file" | awk '{print $2}')
    id_name=$(awk "NR==$private_line" "$model_file" | awk '{print $3}')

    if [[ "${id_name: -1}" == ";" ]]; then
        id_name="${id_name::-1}"  # Remove the last character
    fi

    # Create Static<ModelName>.java
    static_file="$TEST_BASE_DIR/static_object/Static${model_name}.java"
    echo "package ${base_package_name}.static_object;" > "$static_file"
    echo "" >> "$static_file"
    if [ "$request_exists" = true ]; then
        echo "import ${base_package_name}.dto.request.${model_name}DtoRequest;" >> "$static_file"
    fi
    if [ "$response_exists" = true ]; then
        echo "import ${base_package_name}.dto.response.${model_name}DtoResponse;" >> "$static_file"
    fi
    echo "import ${base_package_name}.model.$class_name;" >> "$static_file"
    echo "" >> "$static_file"
    if grep -q " LocalDateTime " "$model_file"; then
        echo "import java.time.LocalDateTime;" >> "$static_file"
    fi
    if grep -q " BigDecimal " "$model_file"; then
        echo "import java.math.BigDecimal;" >> "$static_file"
    fi
    echo "" >> "$static_file"
    echo "public class Static${model_name} {" >> "$static_file"
    echo "" >> "$static_file"
    case "$id_type" in
            "String") echo "    public static final ${id_type} ID = \"${id_name}\";" >> "$static_file" ;;
            "Long") echo "    public static final ${id_type} ID = 1L;" >> "$static_file" ;;
            "Integer") echo "    public static final ${id_type} ID = 1;" >> "$static_file" ;;
            *) echo "    public static final ${id_type} ID = null" ;;
        esac

    echo "" >> "$static_file"
    echo "    public static ${class_name} ${lowercase_model_name}1() {" >> "$static_file"
    echo "        ${class_name} model = new ${class_name}();" >> "$static_file"
    # Map the fields from model
    grep -E 'private .*;' "$model_file" | sed 's/private \([^ ]*\) \([^;]*\);/\1 \2/' | while read -r field; do
        field_type=$(echo "$field" | awk '{print $1}')
        field_name=$(echo "$field" | awk '{print $2}')

        if [ "$field_name" == "id" ] ; then
            echo "        model.setId(ID);" >> "$static_file"
        else
            case "$field_type" in
                "String") echo "        model.set${field_name^}(\"$field_name\");" >> "$static_file" ;;
                "Long") echo "        model.set${field_name^}(1L);" >> "$static_file" ;;
                "Integer") echo "        model.set${field_name^}(1);" >> "$static_file" ;;
                "BigDecimal") echo "        model.set${field_name^}(new BigDecimal(10));" >> "$static_file" ;;
                "LocalDateTime") echo "        model.set${field_name^}(LocalDateTime.MIN);" >> "$static_file" ;;
                "Double") echo "        model.set${field_name^}(10D);" >> "$static_file" ;;
                *) 
                    if [[ "$field_type" == *List* || "$field_type" == *Set* || "$field_type" == *Collection* ]]; then
                        :
                    else 
                        if [[ $field_type == *Model ]]; then
                            field_type="${field_type%Model}"
                        fi
                        lowercase_field_type=$(echo "${field_type:0:1}" | tr '[:upper:]' '[:lower:]')${field_type:1}
                        echo "        model.set${field_name^}(Static$field_type.${lowercase_field_type}1());"  >> "$static_file"
                    fi ;;
            esac
        fi
    done
    echo "        return model;" >> "$static_file"
    echo "    }" >> "$static_file"

    echo "" >> "$static_file"
    echo "    public static ${class_name} ${lowercase_model_name}2() {" >> "$static_file"
    echo "        ${class_name} model = new ${class_name}();" >> "$static_file"
    # Map the fields from model
    grep -E 'private .*;' "$model_file" | sed 's/private \([^ ]*\) \([^;]*\);/\1 \2/' | while read -r field; do
        field_type=$(echo "$field" | awk '{print $1}')
        field_name=$(echo "$field" | awk '{print $2}')

        if [ "$field_name" == "id" ] ; then
            echo "        model.setId(ID);" >> "$static_file"
        else
            case "$field_type" in
                "String") echo "        model.set${field_name^}(\"$field_name\");" >> "$static_file" ;;
                "Long") echo "        model.set${field_name^}(2L);" >> "$static_file" ;;
                "Integer") echo "        model.set${field_name^}(2);" >> "$static_file" ;;
                "BigDecimal") echo "        model.set${field_name^}(new BigDecimal(20));" >> "$static_file" ;;
                "LocalDateTime") echo "        model.set${field_name^}(LocalDateTime.MIN);" >> "$static_file" ;;
                "Double") echo "        model.set${field_name^}(20D);" >> "$static_file" ;;
                *) 
                    if [[ "$field_type" == *List* || "$field_type" == *Set* || "$field_type" == *Collection* ]]; then
                        :
                    else 
                        if [[ "$field_type" == *Model ]]; then
                            field_type="${field_type%Model}"
                        fi
                        lowercase_field_type=$(echo "${field_type:0:1}" | tr '[:upper:]' '[:lower:]')${field_type:1}
                        echo "        model.set${field_name^}(Static$field_type.${lowercase_field_type}2());"  >> "$static_file"
                    fi ;;
            esac
        fi
    done
    echo "        return model;" >> "$static_file"
    echo "    }" >> "$static_file"

    if [ "$request_exists" = true ]; then
        echo "" >> "$static_file"
        echo "    public static ${model_name}DtoRequest ${lowercase_model_name}DtoRequest1() {" >> "$static_file"
        echo "        ${model_name}DtoRequest dtoRequest = new ${model_name}DtoRequest();" >> "$static_file"
        # Map the fields from requestDto
        grep -E 'private .*;' "${BASE_DIR}/dto/request/${model_name}DtoRequest.java" | sed 's/private \([^ ]*\) \([^;]*\);/\1 \2/' | while read -r field; do
            field_type=$(echo "$field" | awk '{print $1}')
            field_name=$(echo "$field" | awk '{print $2}')
            case "$field_type" in
                "String") echo "        dtoRequest.set${field_name^}(\"${field_name}\");" >> "$static_file" ;;
                "Long") echo "        dtoRequest.set${field_name^}(1L);" >> "$static_file" ;;
                "Integer") echo "        dtoRequest.set${field_name^}(1);" >> "$static_file" ;;
                "BigDecimal") echo "        dtoRequest.set${field_name^}(new BigDecimal(10));" >> "$static_file" ;;
                "LocalDateTime") echo "        dtoRequest.set${field_name^}(LocalDateTime.MIN);" >> "$static_file" ;;
                "Double") echo "        dtoRequest.set${field_name^}(10D);" >> "$static_file" ;;
                *)  
                    if [[ "$field_type" == *List* || "$field_type" == *Set* || "$field_type" == *Collection* ]]; then
                        :
                    else 
                        if [[ $field_type == *DtoRequest ]]; then
                            field_type="${field_type%DtoRequest}"
                        fi
                        lowercase_field_type=$(echo "${field_type:0:1}" | tr '[:upper:]' '[:lower:]')${field_type:1}
                        echo "        dtoResponse.set${field_name^}(Static$field_type.${lowercase_field_type1}DtoRequest());"  >> "$static_file"
                    fi ;;
            esac
        done
        echo "        return dtoRequest;" >> "$static_file"
        echo "    }" >> "$static_file"
    fi

    if [ "$response_exists" = true ]; then
        echo "" >> "$static_file"
        echo "    public static ${model_name}DtoResponse ${lowercase_model_name}DtoResponse1() {" >> "$static_file"
        echo "        ${model_name}DtoResponse dtoResponse = new ${model_name}DtoResponse();" >> "$static_file"
        # Map the fields from requestDto
        grep -E 'private .*;' "${BASE_DIR}/dto/response/${model_name}DtoResponse.java" | sed 's/private \([^ ]*\) \([^;]*\);/\1 \2/' | while read -r field; do
            field_type=$(echo "$field" | awk '{print $1}')
            field_name=$(echo "$field" | awk '{print $2}')
            if [ "$field_name" == "id" ] ; then
                echo "        dtoResponse.setId(ID);" >> "$static_file"
            else
                case "$field_type" in
                    "String") echo "        dtoResponse.set${field_name^}(\"${field_name}\");" >> "$static_file" ;;
                    "Long") echo "        dtoResponse.set${field_name^}(1L);" >> "$static_file" ;;
                    "Integer") echo "        dtoResponse.set${field_name^}(1);" >> "$static_file" ;;
                    "BigDecimal") echo "        dtoResponse.set${field_name^}(new BigDecimal(10));" >> "$static_file" ;;
                    "LocalDateTime") echo "        dtoResponse.set${field_name^}(LocalDateTime.MIN);" >> "$static_file" ;;
                    "Double") echo "        dtoResponse.set${field_name^}(10D);" >> "$static_file" ;;
                    *)
                        if [[ "$field_type" == *List* || "$field_type" == *Set* || "$field_type" == *Collection* ]]; then
                            :
                        else 
                            if [[ $field_type == *DtoResponse ]]; then
                                field_type="${field_type%DtoResponse}"
                            fi
                            lowercase_field_type=$(echo "${field_type:0:1}" | tr '[:upper:]' '[:lower:]')${field_type:1}
                            echo "        dtoResponse.set${field_name^}(Static$field_type.${lowercase_field_type}DtoResponse1());"  >> "$static_file"
                        fi ;;
                esac
            fi
        done
        echo "        return dtoResponse;" >> "$static_file"
        echo "    }" >> "$static_file"
    fi

    if [ "$response_exists" = true ]; then
        echo "" >> "$static_file"
        echo "    public static ${model_name}DtoResponse ${lowercase_model_name}DtoResponse2() {" >> "$static_file"
        echo "        ${model_name}DtoResponse dtoResponse = new ${model_name}DtoResponse();" >> "$static_file"
        # Map the fields from requestDto
        grep -E 'private .*;' "${BASE_DIR}/dto/response/${model_name}DtoResponse.java" | sed 's/private \([^ ]*\) \([^;]*\);/\1 \2/' | while read -r field; do
            field_type=$(echo "$field" | awk '{print $1}')
            field_name=$(echo "$field" | awk '{print $2}')
            if [ "$field_name" == "id" ] ; then
                echo "        dtoResponse.setId(ID);" >> "$static_file"
            else
                case "$field_type" in
                    "String") echo "        dtoResponse.set${field_name^}(\"${field_name}\");" >> "$static_file" ;;
                    "Long") echo "        dtoResponse.set${field_name^}(2L);" >> "$static_file" ;;
                    "Integer") echo "        dtoResponse.set${field_name^}(2);" >> "$static_file" ;;
                    "BigDecimal") echo "        dtoResponse.set${field_name^}(new BigDecimal(20));" >> "$static_file" ;;
                    "LocalDateTime") echo "        dtoResponse.set${field_name^}(LocalDateTime.MIN);" >> "$static_file" ;;
                    "Double") echo "        dtoResponse.set${field_name^}(20D);" >> "$static_file" ;;
                    *)
                        if [[ "$field_type" == *List* || "$field_type" == *Set* || "$field_type" == *Collection* ]]; then
                            :
                        else 
                            if [[ $field_type == *DtoResponse ]]; then
                                field_type="${field_type%DtoResponse}"
                            fi
                            lowercase_field_type=$(echo "${field_type:0:1}" | tr '[:upper:]' '[:lower:]')${field_type:1}
                            echo "        dtoResponse.set${field_name^}(Static$field_type.${lowercase_field_type}DtoResponse1());"  >> "$static_file"
                        fi ;;
                esac
            fi
        done
        echo "        return dtoResponse;" >> "$static_file"
        echo "    }" >> "$static_file"
    fi
    echo "}" >> "$static_file"
}

# Iterate over all Java files in the models directory
if [ "$GEN_MODEL" = "All Models" ]; then
    for model_file in "$MODELS_DIR"/*.java; do
        model_name=$(basename "$model_file" .java)
        if [[ $model_name == *Model ]]; then
            model_name_without_suffix="${model_name%Model}"
            create_static_object_classes "$model_name" "$model_name_without_suffix"
        else
            create_static_object_classes "$model_name"
        fi
    done
else
    model_file="$MODELS_DIR"/"$GEN_MODEL".java
    model_name=$GEN_MODEL
    if [[ $model_name == *Model ]]; then
        model_name_without_suffix="${model_name%Model}"
        create_static_object_classes "$model_name" "$model_name_without_suffix"
    else
        create_static_object_classes "$model_name"
    fi
fi

echo "Static Object classes generated successfully"

# Generate Service Tests----------------------------------------------------------------------------------------------------------------
process_temp_file() {
    local service_test_file="$1"
    if [ -f "temp" ]; then
        while IFS= read -r service; do
            object="${service%Service}"
            lowercase_object=$(echo "${object:0:1}" | tr '[:upper:]' '[:lower:]')${object:1}
            service_name=$(echo "${service:0:1}" | tr '[:upper:]' '[:lower:]')${service:1}
            echo "        when($service_name.getById(Static${object}.ID)).thenReturn(Static${object}.${lowercase_object}1());" >> "$service_test_file"
        done < "temp"
    fi
}
mkdir -p "$TEST_BASE_DIR/service"
create_service_tests() {
    local model_name="$1"
    local class_name="$1"
    if [ $# -eq 2 ]; then
        model_name="$2"  # Set model_name to second argument
    fi

    # Check if service exists
    service_exist=false
    if [ -e "$BASE_DIR/service/${model_name}Service.java" ] ; then
        service_exist=true
    fi
    if [ "$service_exist" = false ] ; then
        return
    fi

    local lowercase_model_name=$(echo "${model_name:0:1}" | tr '[:upper:]' '[:lower:]')${model_name:1}

    service_test_file="$TEST_BASE_DIR/service/${model_name}ServiceTest.java"
    service_file="$BASE_DIR/service/${model_name}Service.java"
    echo "package ${base_package_name}.service;" > "$service_test_file"
    echo "" >> "$service_test_file"
    while IFS= read -r line && [[ ! "$line" == *"import lombok.extern.slf4j"* ]]; do
        echo "$line" >> "$service_test_file"
    done < <(tail -n +2 $service_file)
    echo "import ${base_package_name}.static_object.Static${model_name};" >> "$service_test_file"
    
    first_line=$(grep -m 1 "private final" "$service_file")
    while IFS= read -r object; do
        echo "$object" >> "temp"
        object="${object%Service}"
        echo "import ${base_package_name}.static_object.Static${object};" >> "$service_test_file"
    done < <(grep "private final" "$service_file" | sed '1d; s/private final \([^ ]*\) .*/\1/' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    sed "s/\${model_name}/${model_name}/g; s/\${lowercase_model_name}/${lowercase_model_name}/g" "$STATIC_FILES_TEST_DIR/service/static1" >> "$service_test_file"
    
    if [ -f "temp" ]; then
        while IFS= read -r object; do
            echo "    @Mock" >> "$service_test_file"
            echo "    private $object $(echo "${object:0:1}" | tr '[:upper:]' '[:lower:]')${object:1};" >> "$service_test_file"
        done < "temp"
    fi

    sed "s/\${model_name}/${model_name}/g; s/\${lowercase_model_name}/${lowercase_model_name}/g; s/\${class_name}/${class_name}/g" "$STATIC_FILES_TEST_DIR/service/static2" >> "$service_test_file"

    process_temp_file "$service_test_file"

    sed "s/\${model_name}/${model_name}/g; s/\${lowercase_model_name}/${lowercase_model_name}/g; s/\${class_name}/${class_name}/g" "$STATIC_FILES_TEST_DIR/service/static3" >> "$service_test_file"

    if [ -f "temp" ]; then
        while IFS= read -r service; do
            object="${object%Service}"
            service_name=$(echo "${service:0:1}" | tr '[:upper:]' '[:lower:]')${service:1}
            echo "        verify(${service_name}, times(1)).getById(Static${object}.ID);" >> "$service_test_file"
        done < "temp"
    fi
    echo "        verify(${lowercase_model_name}Repository, times(1)).save(${lowercase_model_name});" >> "$service_test_file"
    echo "    }" >> "$service_test_file"
    echo "" >> "$service_test_file"
    
    if [ -f "temp" ]; then
        assertion=
        verification=
        while IFS= read -r service; do
            object="${service%Service}"
            lowercase_object=$(echo "${object:0:1}" | tr '[:upper:]' '[:lower:]')${object:1}
            echo "    @Test" >> "$service_test_file"
            echo "    void testCreate_EntityNotFoundException_${object}NotFound() {" >> "$service_test_file"
            object="${service%Service}"
            service_name=$(echo "${service:0:1}" | tr '[:upper:]' '[:lower:]')${service:1}
            if [ -n "$assertion" ]; then
                echo -e "$assertion" >> "$service_test_file"
            fi
            echo "        when($service_name.getById(Static${object}.ID)).thenThrow(new EntityNotFoundException(\"${object} not found\"));" >> "$service_test_file"
            echo "" >> "$service_test_file"
            echo "        EntityNotFoundException exception = assertThrows(EntityNotFoundException.class, () -> ${lowercase_model_name}Service.create(${lowercase_model_name}));" >> "$service_test_file"
            echo "" >> "$service_test_file"
            echo "        assertNotNull(exception);" >> "$service_test_file"
            echo "        assertEquals(\"${object} not found\", exception.getMessage());" >> "$service_test_file"
            verification="${verification}        verify(${service_name}, times(1)).getById(Static${object}.ID);"
            echo -e "$verification" >> "$service_test_file"
            echo "        verifyNoInteractions(${lowercase_model_name}Repository);" >> "$service_test_file"
            echo "    }" >> "$service_test_file"
            echo "" >> "$service_test_file"
            if [ -n "$assertion" ]; then
                assertion="${assertion}\n"
            fi
            verification="${verification}\n"
            assertion="${assertion}        when(${service_name}.getById(Static${object}.ID)).thenReturn(Static${object}.${lowercase_object}1());"
        done < "temp"
    fi
    echo "    @Test" >> "$service_test_file"
    echo "    void testCreate_DataAccessException() {" >> "$service_test_file"
    process_temp_file "$service_test_file"
    sed "s/\${model_name}/${model_name}/g; s/\${lowercase_model_name}/${lowercase_model_name}/g; s/\${class_name}/${class_name}/g" "$STATIC_FILES_TEST_DIR/service/static4" >> "$service_test_file"
    process_temp_file "$service_test_file"
    sed "s/\${model_name}/${model_name}/g; s/\${lowercase_model_name}/${lowercase_model_name}/g; s/\${class_name}/${class_name}/g" "$STATIC_FILES_TEST_DIR/service/static5" >> "$service_test_file"
    if [ -f "temp" ]; then
        assertion=
        verification=
        while IFS= read -r service; do
            object="${service%Service}"
            lowercase_object=$(echo "${object:0:1}" | tr '[:upper:]' '[:lower:]')${object:1}
            echo "    @Test" >> "$service_test_file"
            echo "    void testUpdateById_EntityNotFoundException_${object}NotFound() {" >> "$service_test_file"
            echo "        when(${lowercase_model_name}Repository.findById(Static${model_name}.ID)).thenReturn(java.util.Optional.of(${lowercase_model_name}));" >> "$service_test_file"
            object="${service%Service}"
            service_name=$(echo "${service:0:1}" | tr '[:upper:]' '[:lower:]')${service:1}
            if [ -n "$assertion" ]; then
                echo -e "$assertion" >> "$service_test_file"
            fi
            echo "        when($service_name.getById(Static${object}.ID)).thenThrow(new EntityNotFoundException(\"${object} not found\"));" >> "$service_test_file"
            echo "" >> "$service_test_file"
            echo "        EntityNotFoundException exception = assertThrows(EntityNotFoundException.class, () -> ${lowercase_model_name}Service.updateById(Static${model_name}.ID, ${lowercase_model_name}));" >> "$service_test_file"
            echo "" >> "$service_test_file"
            echo "        assertNotNull(exception);" >> "$service_test_file"
            echo "        assertEquals(\"${object} not found\", exception.getMessage());" >> "$service_test_file"
            verification="${verification}        verify(${service_name}, times(1)).getById(Static${object}.ID);"
            echo -e "$verification" >> "$service_test_file"
            echo "    }" >> "$service_test_file"
            echo "" >> "$service_test_file"
            if [ -n "$assertion" ]; then
                assertion="${assertion}\n"
            fi
            verification="${verification}\n"
            assertion="${assertion}        when(${service_name}.getById(Static${object}.ID)).thenReturn(Static${object}.${lowercase_object}1());"
        done < "temp"
    fi
    sed "s/\${model_name}/${model_name}/g; s/\${lowercase_model_name}/${lowercase_model_name}/g; s/\${class_name}/${class_name}/g" "$STATIC_FILES_TEST_DIR/service/static6" >> "$service_test_file"
    process_temp_file "$service_test_file"
    sed "s/\${model_name}/${model_name}/g; s/\${lowercase_model_name}/${lowercase_model_name}/g; s/\${class_name}/${class_name}/g" "$STATIC_FILES_TEST_DIR/service/static7" >> "$service_test_file"
    
    if [ -f "temp" ]; then
        rm "temp"
    fi
}

# Iterate over all Java files in the models directory
if [ "$GEN_MODEL" = "All Models" ]; then
    for model_file in "$MODELS_DIR"/*.java; do
        model_name=$(basename "$model_file" .java)
        if [[ $model_name == *Model ]]; then
            model_name_without_suffix="${model_name%Model}"
            create_service_tests "$model_name" "$model_name_without_suffix"
        else
            create_service_tests "$model_name"
        fi
    done
else
    model_file="$MODELS_DIR"/"$GEN_MODEL".java
    model_name=$GEN_MODEL
    if [[ $model_name == *Model ]]; then
        model_name_without_suffix="${model_name%Model}"
        create_service_tests "$model_name" "$model_name_without_suffix"
    else
        create_service_tests "$model_name"
    fi
fi

echo "Service layer tests generated successfully"

# Generate Controller Tests---------------------------------------------------------------------------------------------------------------------------
mkdir -p "$TEST_BASE_DIR/controller"
create_controller_tests() {
    local model_name="$1"
    local class_name="$1"
    if [ $# -eq 2 ]; then
        model_name="$2"  # Set model_name to second argument
    fi

    # Check if controller exists
    controller_exist=false
    if [ -e "$BASE_DIR/controller/${model_name}Controller.java" ] ; then
        controller_exist=true
    fi
    if [ "$controller_exist" = false ] ; then
        return
    fi

    local lowercase_model_name=$(echo "${model_name:0:1}" | tr '[:upper:]' '[:lower:]')${model_name:1}
    controller_test_file="$TEST_BASE_DIR/controller/${model_name}ControllerTest.java"
    controller_file="$BASE_DIR/controller/${model_name}Controller.java"
    controller_api="/"
    while IFS= read -r line; do
        if [[ $line == *"@RequestMapping("* ]]; then
            controller_api=$(echo "$line" | grep -o '"[^"]*"' | sed 's/"//g')
            break
        fi
    done < "$controller_file"
    # Prepare temp file with checks
    field_count=0
    while IFS= read -r line; do
        if [[ $line == *"private "* ]]; then
            field_count=$((field_count + 1))
        fi
    done < "$BASE_DIR/dto/response/${model_name}DtoResponse.java"
    while IFS= read -r line; do
        if [[ $line == *"private "* ]]; then
            field_count=$((field_count - 1))
            type_name=$(echo "$line" | awk '{print substr($2, 1)}')
            var_name=$(echo "$line" | awk '{print substr($3, 1, length($3)-1)}')
            uppercase_var_name=$(echo "${var_name:0:1}" | tr '[:lower:]' '[:upper:]')${var_name:1}
            line=
            if [ -f "$BASE_DIR/dto/response/$type_name.java" ]; then
                line=".andExpect(jsonPath(\"$.${var_name}.id\").value(${lowercase_model_name}Response.get${uppercase_var_name}().getId()))"
            else
                line=".andExpect(jsonPath(\"$.${var_name}\").value(${lowercase_model_name}Response.get${uppercase_var_name}()"
                if [ "$type_name" == "LocalDateTime" ]; then
                    line="$line.format(formatter)))"
                else
                    line="$line))"
                fi
            fi
            if [ "$field_count" -eq 0 ]; then
                line="$line;"
            fi
            echo "                $line" >> "temp"
        fi
    done < "$BASE_DIR/dto/response/${model_name}DtoResponse.java"
    
    echo "package ${base_package_name}.controller;" > "$controller_test_file"
    echo "" >> "$controller_test_file"
    echo "import com.fasterxml.jackson.databind.ObjectMapper;" >> "$controller_test_file"
    while IFS= read -r line && [[ ! "$line" == *".service."* ]]; do
        echo "$line" >> "$controller_test_file"
    done < <(tail -n +4 $controller_file)
    echo "import ${base_package_name}.exception.EntityNotFoundException;" >> "$controller_test_file"
    echo "import ${base_package_name}.service.${model_name}Service;" >> "$controller_test_file"
    echo "import ${base_package_name}.static_object.Static${model_name};" >> "$controller_test_file"
    echo "import ${base_package_name}.exception.GlobalExceptionHandler;" >> "$controller_test_file"
    sed "s~\${model_name}~$model_name~g; s~\${lowercase_model_name}~$lowercase_model_name~g; s~\${controller_api}~$controller_api~g; s~\${class_name}~$class_name~g" "$STATIC_FILES_TEST_DIR/controller/static1_1" >> "$controller_test_file"

    if grep -q " LocalDateTime " "$MODELS_DIR/$class_name.java"; then
        date_exist=true
    else
        date_exist=false
    fi
    if [ "$date_exist" = true ]; then
        echo "import java.time.format.DateTimeFormatter;" >> "$controller_test_file"
    fi
    sed "s~\${model_name}~$model_name~g; s~\${lowercase_model_name}~$lowercase_model_name~g; s~\${controller_api}~$controller_api~g; s~\${class_name}~$class_name~g" "$STATIC_FILES_TEST_DIR/controller/static1_2" >> "$controller_test_file"
    if [ "$date_exist" = true ]; then
        echo "    private final DateTimeFormatter formatter = DateTimeFormatter.ofPattern(\"yyyy-MM-dd'T'HH:mm:ss\");" >> "$controller_test_file"
    fi
    sed "s~\${model_name}~$model_name~g; s~\${lowercase_model_name}~$lowercase_model_name~g; s~\${controller_api}~$controller_api~g; s~\${class_name}~$class_name~g" "$STATIC_FILES_TEST_DIR/controller/static1_3" >> "$controller_test_file"
    
    cat "temp" >> "$controller_test_file" 
    sed "s~\${model_name}~$model_name~g; s~\${lowercase_model_name}~$lowercase_model_name~g; s~\${controller_api}~$controller_api~g; s~\${class_name}~$class_name~g" "$STATIC_FILES_TEST_DIR/controller/static2" >> "$controller_test_file"
    cat "temp" >> "$controller_test_file" 
    sed "s~\${model_name}~$model_name~g; s~\${lowercase_model_name}~$lowercase_model_name~g; s~\${controller_api}~$controller_api~g; s~\${class_name}~$class_name~g" "$STATIC_FILES_TEST_DIR/controller/static3" >> "$controller_test_file"
    cat "temp" >> "$controller_test_file" 
    sed "s~\${model_name}~$model_name~g; s~\${lowercase_model_name}~$lowercase_model_name~g; s~\${controller_api}~$controller_api~g; s~\${class_name}~$class_name~g" "$STATIC_FILES_TEST_DIR/controller/static4" >> "$controller_test_file"
    
    rm temp
}

# Iterate over all Java files in the models directory
if [ "$GEN_MODEL" = "All Models" ]; then
    for model_file in "$MODELS_DIR"/*.java; do
        model_name=$(basename "$model_file" .java)
        if [[ $model_name == *Model ]]; then
            model_name_without_suffix="${model_name%Model}"
            create_controller_tests "$model_name" "$model_name_without_suffix"
        else
            create_controller_tests "$model_name"
        fi
    done
else
    model_file="$MODELS_DIR"/"$GEN_MODEL".java
    model_name=$GEN_MODEL
    if [[ $model_name == *Model ]]; then
        model_name_without_suffix="${model_name%Model}"
        create_controller_tests "$model_name" "$model_name_without_suffix"
    else
        create_controller_tests "$model_name"
    fi
fi

echo "Controller layer tests generated successfully"