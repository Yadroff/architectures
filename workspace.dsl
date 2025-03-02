workspace "Cloud" "Приложение облачного хранилища" {
    !identifiers hierarchical

    model {
        user = person "Пользователь" "Пользователь облачного хранилища"
        userSystem = softwareSystem "Система пользователей" {
            description "Отвечает за управление пользователями и их данными"
            userDb = container "База данных пользователей"{
                description "Хранит данные пользователей"
                technology "PostgreSQL"
                tags "Database"
            }
            userService = container "Сервис пользователей" {
                description "Обрабатывает запросы, связанные с пользователями" 
                technology "C++, Userver"
                -> userDb "Читает/записывает данные"
            }
        }

        storageSystem = softwareSystem "Система хранения" {
            description "Отвечает за хранение и управление файлами"

            encryptionService = container "Сервис шифрования"{
                description "Шифрует и дешифрует файлы." 
                technology "C++, Userver, OpenSSL"
            } 
            storageDb = container "База данных хранения" {
                description "Хранит метаинформацию о файлах" 
                technology "PostgreSQL"
                tags "Database"
            }
            fileStorage = container "Хранилище файлов" {
                description "Хранит зашифрованные файлы" 
                technology "Amazon S3"
                tags "Database"
            }

            fileSystemService = container "Сервис файловой системы" {
                description "Управляет метаинформацией о файлах и взаимодействует с S3" 
                technology "C++, Userver"
                -> encryptionService "Шифрует/дешифрует файлы"
                -> storageDb "Читает/записывает метаинформацию"
                -> fileStorage "Читает/записывает файлы"
            }
        }

        user -> userSystem "Использует для регистрации и авторизации"
        user -> storageSystem "Использует для загрузки и скачивания файлов"

        user -> userSystem.userService "Редактирует данные своего аккаунта"
        user -> storageSystem.fileSystemService "Использует для хранения файлов"

        prod = deploymentEnvironment "PROD" {
            deploymentNode "Userver" "Сервисы Userver" {
                deploymentNode "K8S" "Kubernetes Cluster" {
                    containerInstance userSystem.userService
                    containerInstance storageSystem.encryptionService
                    containerInstance storageSystem.fileSystemService
                }

                deploymentNode "RDS" "Relational Database Service" {
                    containerInstance userSystem.userDb
                    containerInstance storageSystem.storageDb
                }

                deploymentNode "S3" "Simple Storage Service" {
                    containerInstance storageSystem.fileStorage
                }
            }
        }
    }

    views {
        themes default

        properties { 
            structurizr.tooltips true
        }

        systemContext userSystem "SystemContext" "Диаграмма контекста системы" {
            include user userSystem storageSystem
            autoLayout
        }

        container userSystem "UserSystemContainerDiagram" "Диаграмма контейнеров системы пользователей" {
            include user userSystem userSystem.userService userSystem.userDb
            autoLayout
        }

        container storageSystem "StorageSystemContainerDiagram" "Диаграмма контейнеров системы хранения" {
            include storageSystem storageSystem.encryptionService storageSystem.storageDb storageSystem.fileStorage storageSystem.fileSystemService
            autoLayout
        }

        deployment userSystem "PROD" "UserSystemProdDeployment" {
            include *
            autoLayout
        }

        deployment storageSystem "PROD" "StorageSystemProdDeployment" {
            include *
            autoLayout
        }

        dynamic userSystem "UseCase01" "Добавление нового пользователя" {
            autoLayout
            user -> userSystem.userService "Создать нового пользователя (POST)"
            userSystem.userService -> userSystem.userDb "Сохранить данные о пользователе"
        }

        dynamic userSystem "UseCase02" "Поиск пользователя по лоигну" {
            autoLayout
            user -> userSystem.userService "Найти пользователя (GET)"
            userSystem.userService -> userSystem.userDb "Найти данные о пользователе"
        }

        dynamic userSystem "UseCase03" "Поиск пользователя по имени и фамилии" {
            autoLayout
            user -> userSystem.userService "Найти пользователя (GET)"
            userSystem.userService -> userSystem.userDb "Найти данные о пользователе"
        }

        dynamic storageSystem "UseCase04" "Создание новой папки" {
            autoLayout
            user -> storageSystem.fileSystemService "Создать папку (POST)"
            storageSystem.fileSystemService -> storageSystem.storageDb "Сохранить данные о папке"
        }

        dynamic storageSystem "UseCase05" "Получение списка всех папок" {
            autoLayout
            user -> storageSystem.fileSystemService "Получение списка всех папок (GET)"
            storageSystem.fileSystemService -> storageSystem.storageDb "Собрать данные о всех папках"
        }

        dynamic storageSystem "UseCase06" "Добавление файла в папку" {
            autoLayout
            user -> storageSystem.fileSystemService "Сохранить файл (POST)"
            storageSystem.fileSystemService -> storageSystem.storageDb "Сохранить метаинформацию о файле"
            storageSystem.fileSystemService -> storageSystem.fileStorage "Сохранить файл"   
        }

        dynamic storageSystem "UseCase07" "Поиск файла по имени" {
            autoLayout
            user -> storageSystem.fileSystemService "Поиск файла по имени (GET)"
            storageSystem.fileSystemService -> storageSystem.storageDb "Получить метаинформацию о файле"
            storageSystem.fileSystemService -> storageSystem.fileStorage "Получить файл"
        }

        dynamic storageSystem "UseCase08" "Удаление файла" {
            autoLayout
            user -> storageSystem.fileSystemService "Удалить файл (POST)"
            storageSystem.fileSystemService -> storageSystem.storageDb "Получить метаинформацию о файле"
            storageSystem.fileSystemService -> storageSystem.fileStorage "Удалить файл"
            storageSystem.fileSystemService -> storageSystem.storageDb "Удалить метаинформацию файла"
        }

        dynamic storageSystem "UseCase09" "Удаление папки" {
            autoLayout
            user -> storageSystem.fileSystemService "Удалить папку (POST)"
            storageSystem.fileSystemService -> storageSystem.storageDb "Получить список файлов в папке"
            storageSystem.fileSystemService -> storageSystem.fileStorage "Удалить файлы"
            storageSystem.fileSystemService -> storageSystem.storageDb "Удалить файлы и подпапки"
        }

        styles {
            element "Person" {
                background #FFD700
                color #000000
            }
            element "Software System" {
                background #87CEEB
                color #000000
            }
            element "Container" {
                background #90EE90
                color #000000
            }
            element "Database" {
                shape Cylinder
                background #FFA07A
                color #000000
            }
            element "Deployment Node" {
                background #D3D3D3
                color #000000       
                shape Box
                border solid        
            }
        }
    }
}