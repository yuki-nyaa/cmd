cmake_minimum_required(VERSION 3.12)
project(yuki.cmd VERSION 1.0)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_FLAGS_DEBUG "-Wextra -g -O0")
set(CMAKE_CXX_FLAGS_RELEASE "-O2")

if(NOT CMAKE_BUILD_TYPE)
    message("No build type specified. Defaulted to 'Release'.")
    set(CMAKE_BUILD_TYPE Release)
endif()

if(CMAKE_BUILD_TYPE MATCHES Debug)
    set(YUKI_PG_DBG TRUE)
    message("Build type: Debug")
else()
    set(YUKI_PG_DBG FALSE)
    message("Build type: Release")
endif()

include_directories(/usr/local/include ${PROJECT_SOURCE_DIR} ${PROJECT_BINARY_DIR})
link_directories(/usr/local/lib)

add_custom_command(OUTPUT cmd.hpp
    COMMAND reflex ${PROJECT_SOURCE_DIR}/cmd.l
    DEPENDS cmd.l
    COMMENT "RE/flex-ing cmd.l")
add_custom_target(cmd
    ALL
    DEPENDS cmd.hpp)

install(FILES ${PROJECT_BINARY_DIR}/cmd.hpp DESTINATION include/yuki)
