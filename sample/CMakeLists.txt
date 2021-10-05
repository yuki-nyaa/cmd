cmake_minimum_required(VERSION 3.10)
project(yuki.cmd.sample VERSION 1.0)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_FLAGS_DEBUG "-Wextra -g -O0")
set(CMAKE_CXX_FLAGS_RELEASE "-O2")

if(NOT CMAKE_BUILD_TYPE)
    message("No build type specified. Defaulted to 'Debug'.")
    set(CMAKE_BUILD_TYPE Debug)
endif()

if(CMAKE_BUILD_TYPE MATCHES Debug)
    set(YUKI_CMD_DBG TRUE)
    message("Build type: Debug")
else()
    set(YUKI_CMD_DBG FALSE)
    message("Build type: Release")
endif()

if(MINGW)
    set(USR "mingw64")
else()
    set(USR "usr")
endif()
set(LOCAL_INCLUDE /${USR}/local/include)
set(LOCAL_LIB /${USR}/local/lib)

include_directories(${LOCAL_INCLUDE} ${PROJECT_SOURCE_DIR} ${PROJECT_BINARY_DIR})
link_directories(${LOCAL_LIB})

configure_file(cconfig.in cconfig)

add_executable(main main.cpp cmd.cpp)
target_link_libraries(main yuki_cmd reflex fmt)
