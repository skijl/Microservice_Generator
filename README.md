# Microservice Generator (Microsgen)
> The application for generating microservices in SpringBoot
- You can create your own Springboot service with **CRUD operations and full coverage tests** in seconds using only model classes and this application
- On average you would **save 2-6 hours of your time on the service template creation** and would maximaze the focus on the actual logic of your application
- Integrated to work with JPA relations and MongoDB documents
- Best Practices & Design Patterns included
## How to install?
- **Pull with HTTPS -** `git pull https://github.com/skijl/Microservice-Generator.git`
- **Pull with SSH -** `git pull git@github.com:skijl/Microservice-Generator.git`
- **Download ZIP -** `Blue button Code -> Download ZIP`
## How to use?
> You can run .jar application by going to the terminal and typing `java -jar MicrosGen.jar` after what you will see the main window:

![alt text](readme_static/menu_info.png) ![alt text](readme_static/menu.png)
1. **Module/Directory selector** (Select the module directory of your Springboot project)
    - Directory must contain Spring Boot project that contains /model directory that can contain any number of classes of any names, but they must be the actual entities of JPA or documents of Mongo:
    ```
    module-directory/
    │
    ├─ src/
    │  ├─ main/
    │  │  ├─ java/
    │  │  │  ├─ com/
    │  │  │  │  ├─ example/
    │  │  │  │  │  ├── module/
    │  │  │  │  │  │   └── Entity.java      # Entity class (can have any name)
    │  │  │  │  │  ├── Application.java     # Main application class (can have any name)
    ```
    - The script supports only one database type per service.
    - The module directory must have the following structure: 
<<<<<<< HEAD
2. **Model selector** 
    - `All Models` - You can generate code for all the models
    - Othervise you can generate code for only exact model

=======
```
module-directory/
│
├─ src/
│  ├─ main/
│  │  ├─ java/
│  │  │  ├─ com/
│  │  │  │  ├─ example/
│  │  │  │  │  ├── model/
│  │  │  │  │  │   └── Entity.java      # Entity class (can have any name)
│  │  │  │  │  ├── Application.java     # Main application class (can have any name)
```
>>>>>>> 26ebbb458603a3eb8223304b02f1cc204d251613
3. **Generate DTOs** (Generate button for DTOs)
    - The first button you would press after the module directory is fully prepared.
    - Generates the /dto directory with /response & /request classes
    - After this script you would have to look at the generated DTO classes and adjust them if you have your specific requirements
4. **Generate DTO Mapper** (Generate button fro DTO Mappers)
    - After you adjusted your DTOs you press this button to create mapper class/classes for your DTOs
    - Creates directory /dto/mapper with classes for mapping between **Resquest DTO -> Model* & **Model -> ResponseDto*
5. **Generate Service** (The main script that generates all the service)
    - /repository - JPA/Mongo repository layer for the application
    - /exception - Custom exceptions with Controller Advice for the proper exception handling
    - /service - Service Implementation classes with CRUD operations: create/getById/getAll/update/deleteById
    - /controller - Rest Controller with all the endpoints to interract with service layer. Swagger annotations for all the methods
6. **Generate Tests** (Generate Tests button)
    - Generate tests that cover all the code generated by script
    - It includes all the tests for service and controller layer
7. **Previous action**
    - Shows the last action
    - Mainly used to see the last executed script and the success of it
8. **Selected directory**
    - Shows the selected directory module

`If you have any bug/problem/requirement - please send be descriptive email with screenshots - makhrevychmaxim@gmail.com`
