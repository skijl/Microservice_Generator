#!/bin/bash

# Check if the directory path is provided as an argument
if [[ -z "$1" ]]; then
    echo "Usage: $0 <path-to-directory-with-pom.xml>"
    exit 1
fi

# Path to the directory containing the pom.xml file
directory="$1"

# Path to the pom.xml file
pom_file="$directory/pom.xml"

# Check if the pom.xml file exists in the specified directory
if [[ ! -f "$pom_file" ]]; then
    echo "Error: $pom_file not found in $directory!"
    exit 1
fi


# Define the required dependencies

required_dependencies=(
    '        <dependency>'\
    '            <groupId>org.springframework.boot</groupId>'\
    '            <artifactId>spring-boot-starter-validation</artifactId>'\
    '        </dependency>'\
    '        <dependency>'\
    '            <groupId>org.springframework.boot</groupId>'\
    '            <artifactId>spring-boot-starter-web</artifactId>'\
    '        </dependency>'\
    '        <dependency>'\
    '            <groupId>org.projectlombok</groupId>'\
    '            <artifactId>lombok</artifactId>'\
    '        </dependency>'\
    '        <dependency>'\
    '            <groupId>org.springdoc</groupId>'\
    '            <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>'\
    '            <version>2.5.0</version>'\
    '        </dependency>'\
    '        <dependency>'\
    '            <groupId>org.springframework.boot</groupId>'\
    '            <artifactId>spring-boot-starter-test</artifactId>'\
    '            <scope>test</scope>'\
    '        </dependency>'
)


# Function to check if a dependency exists in the pom.xml
dependency_exists() {
     local artifact_id="$1"

     local xml_string=$(<"$pom_file")

     # Check if <dependencies> tag exists
     if [[ ! "$xml_string" =~ "<dependencies>" ]]; then
         echo "Tag 'dependencies' not found in pom.xml"
         exit 1
     fi

     # Check if </dependencies> tag exists
     if [[ ! "$xml_string" =~ "</dependencies>" ]]; then
         echo "Tag '/dependencies' not found in pom.xml"
         exit 1
     fi

     # Extract substring between <dependencies> and </dependencies> tags
     local substring=$(sed -n '/<dependencies>/,/<\/dependencies>/p' "$pom_file")

     # Check if the artifact_id exists within the substring
     if [[ "$substring" =~ $artifact_id ]]; then
         return 0
     else
         return 1
     fi
 }


# Function to add a dependency to the pom.xml using awk
add_dependencies() {
    line_number=$(grep -n '</dependencies>' "$pom_file" | head -n 1 | cut -d ':' -f 1)
    local start_index="$1"
    local found=false
    for ((i = start_index; i < ${#required_dependencies[@]}; i++)); do
        dependency="${required_dependencies[$i]}"
        if [[ "$dependency" == "        </dependency>" ]]; then
            awk -v line_number="$line_number" -v dependency="$dependency" 'NR == line_number { print dependency } 1' "$pom_file" > tmpfile && mv tmpfile "$pom_file"
            return
        else
            awk -v line_number="$line_number" -v dependency="$dependency" 'NR == line_number { print dependency } 1' "$pom_file" > tmpfile && mv tmpfile "$pom_file"
        fi
        ((line_number++))
    done
}

# Add each required dependency if missing
for ((i = 0; i < ${#required_dependencies[@]}; i++)); do
    dependency="${required_dependencies[$i]}"
    if [[ "$dependency" == "        <dependency>" ]]; then
        if ! dependency_exists "${required_dependencies[i+2]//[[:space:]]}"; then
            add_dependencies i
        fi
    fi
done
