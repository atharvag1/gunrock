####################################################
############ INSTALLING CORRECT CMAKE ##############
####################################################
# Installing correct cmake version is easy!
# 1) Find the respective version here;
# https://github.com/Kitware/CMake/releases,
# and 2) replace the [x.xx.x] in the following
# commands with the version number (remove the
# brackets). For example, if you are installing
# CMake 3.22.1, replace [x.xx.x] with 3.22.1:

# wget https://github.com/Kitware/CMake/releases/download/v[x.xx.x]/cmake-[x.xx.x]-linux-x86_64.sh
# chmod +x ./cmake-[x.xx.x]-linux-x86_64.sh
# ./cmake-[x.xx.x]-linux-x86_64.sh
# sudo mv cmake-[x.xx.x]-linux-x86_64 /opt/cmake
# sudo ln -s /opt/cmake/bin/* /usr/local/bin/
cmake_minimum_required(VERSION 3.20.1 FATAL_ERROR)

# begin /* Update Essentials version */
set(ESSENTIALS_VERSION_MAJOR 2)
set(ESSENTIALS_VERSION_MINOR 0)
set(ESSENTIALS_VERSION_PATCH 0)
# end /* Update Essentials version */

set(ESSENTIALS_VERSION "${ESSENTIALS_VERSION_MAJOR}.${ESSENTIALS_VERSION_MINOR}.${ESSENTIALS_VERSION_PATCH}")


message(STATUS "HIP Platform: $ENV{HIP_PLATFORM}")

if("$ENV{HIP_PLATFORM}" STREQUAL "nvidia")
    message(STATUS "HIP PLATFORM IS NVIDIA = " $ENV{HIP_PLATFORM})
      set(HIP_BACKEND_CUDA 1)
      set(target_language CUDA)
        
else()
  set(HIP_BACKEND_CUDA 0)
  set(target_language HIP)
endif()


if("${HIP_BACKEND_CUDA}" STREQUAL "1")
message(STATUS "HIP PLATFORM IS SET TO NVIDIA " )
endif()


project(essentials
  VERSION ${ESSENTIALS_VERSION}
  LANGUAGES CXX C ${target_language}
)

# Apparently defines NDEBUG, such that asserts() are disabled.
# That is what we want for performance.
set(CMAKE_BUILD_TYPE Release)

# begin /* Dependencies directory */
set(PROJECT_DEPS_DIR externals)
# end /* Dependencies directory */

# begin /* Include cmake modules */
include(${PROJECT_SOURCE_DIR}/cmake/FetchThrustCUB.cmake)
#include(${PROJECT_SOURCE_DIR}/cmake/FetchModernGPU.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/FetchCXXOpts.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/FetchRapidJSON.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/FetchNlohmannJson.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/FetchCMakeModules.cmake)
# end /* Include cmake modules */

## Set the directory where the binaries will be stored
set(EXECUTABLE_OUTPUT_PATH
  ${PROJECT_BINARY_DIR}/bin
  CACHE PATH
  "Directory where all executables will be stored")

## Set the directory where the libraries will be stored
set(LIBRARY_OUTPUT_PATH
  ${PROJECT_BINARY_DIR}/lib
  CACHE PATH
  "Directory where all the libraries will be stored")

## Export compile commands
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_VERBOSE_MAKEFILE OFF)

############ ADD LIBRARY: ESSENTIALS (HEADER-ONLY) ############
add_library(essentials INTERFACE)

####################################################
############### SET TARGET PROPERTIES ##############
####################################################
if("${HIP_BACKEND_CUDA}" STREQUAL "1")
set_target_properties(essentials 
  PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF # Should this be turned on for MSVC?
    CUDA_STANDARD 17
    CUDA_STANDARD_REQUIRED ON
    CUDA_EXTENSIONS OFF
    CUDA_RESOLVE_DEVICE_SYMBOLS ON
    CUDA_SEPARABLE_COMPILATION ON
    CUDA_ARCHITECTURES 75 # Set required architecture.
   #  CUDA_PTX_COMPILATION ON # Can only be applied to OBJ.
     )
else()
set_target_properties(essentials 
  PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF # Should this be turned on for MSVC?
    HIP_STANDARD 17
    HIP_STANDARD_REQUIRED ON
    
    HIP_EXTENSIONS OFF
    #CUDA_RESOLVE_DEVICE_SYMBOLS ON
    #CUDA_SEPARABLE_COMPILATION ON
    HIP_ARCHITECTURES gfx90a # Set required architecture.
    # CUDA_PTX_COMPILATION ON # Can only be applied to OBJ.
)
endif()


# Use for later.
if("${HIP_BACKEND_CUDA}" STREQUAL "1")
get_target_property(ESSENTIALS_ARCHITECTURES 
  essentials 
    CUDA_ARCHITECTURES
)
else()
get_target_property(ESSENTIALS_ARCHITECTURES 
  essentials 
    HIP_ARCHITECTURES
)
endif()

# Add GIT SHA-1 definition
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/externals/cmake_modules-src/")
include(GetGitRevisionDescription)
get_git_head_revision(GIT_REFSPEC GIT_SHA1)

####################################################
############ TARGET COMPILER DEFINITIONS ###########
####################################################
target_compile_definitions(essentials
  INTERFACE 
    SM_TARGET=${ESSENTIALS_ARCHITECTURES}
    HIP_BACKEND=${HIP_BACKEND_CUDA}
    ESSENTIALS_VERSION=${ESSENTIALS_VERSION}
    GIT_SHA1="${GIT_SHA1}"
)

message(STATUS "Essentials ${target_language} Architecture: ${ESSENTIALS_ARCHITECTURES}")

####################################################
############ TARGET COMPILE FEATURES ###############
####################################################
# Turn C++ Standard 17 ON.
target_compile_features(essentials INTERFACE cxx_std_17)
# set(CMAKE_CXX_EXTENSIONS OFF)

set(ESSENTIALS_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/include)

####################################################
############ TARGET INCLUDE DIRECTORIES ############
####################################################
target_include_directories(essentials
  INTERFACE ${ESSENTIALS_INCLUDE_DIR}
  INTERFACE ${CXXOPTS_INCLUDE_DIR}
  INTERFACE ${THRUST_INCLUDE_DIR}
  INTERFACE ${CUB_INCLUDE_DIR}
  INTERFACE ${MODERNGPU_INCLUDE_DIR}
  INTERFACE ${RAPIDJSON_INCLUDE_DIR}
  INTERFACE ${NHLOMANN_JSON_INCLUDE_DIR}
  INTERFACE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}
  INTERFACE ${CMAKE_MODULES_INCLUDE_DIR}
)

find_package(Threads)
####################################################
############ TARGET LINK LIBRARIES #################
####################################################

if("${HIP_BACKEND_CUDA}" STREQUAL "1")
target_link_libraries(essentials
  INTERFACE curand
  INTERFACE cuda
  INTERFACE cusparse
  -lstdc++fs
  ${CMAKE_THREAD_LIBS_INIT}
)
else()
target_link_libraries(essentials
  INTERFACE hiprand
  INTERFACE hip
  INTERFACE hipsparse
  -lstdc++fs
  ${CMAKE_THREAD_LIBS_INIT}
)
endif()


####################################################
################# TARGET SOURCES ###################
####################################################
target_sources(essentials
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include/gunrock/util/gitsha1make.c"
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include/gunrock/io/detail/mmio.cpp"
)

####################################################
############## SET CXX & CUDA FLAGS ################
####################################################

if("${HIP_BACKEND_CUDA}" STREQUAL "1")
set(platform_flag __HIP_PLATFORM_NVIDIA__)
else()
set(platform_flag __HIP_PLATFORM_AMD__)
endif()

set(CXX_FLAGS 
  $<$<CXX_COMPILER_ID:MSVC>:
    /W4
  >
  $<$<CXX_COMPILER_ID:GNU>:
     #-std=c++17
    -Wall 
    # -Wextra
    -Wno-unused-result
    -Wno-unused-local-typedefs
    -Wno-strict-aliasing
    -Wno-unused-function
    -Wno-format-security
    -D ${platform_flag}
    # -Werror
    # -vvv
  >
)


set(HIP_FLAGS
  #-std=c++17
  -D ${platform_flag}
  -ferror-limit=100
  #--expt-extended-lambda 
  #--expt-relaxed-constexpr
  #--use_fast_math
  -DHIP_FAST_MATH
  --offload-arch=gfx90a
  #--ptxas-options -v
  #--generate-line-info
  
  $<$<CXX_COMPILER_ID:GNU>:-O3> # Host optimize-level
   --verbose
   --debug # Host debug
  # --device-debug # Device debug
)


set(CUDA_FLAGS
  --expt-extended-lambda 
  --expt-relaxed-constexpr
  --use_fast_math
  --ptxas-options -v
  --generate-line-info
  $<$<CXX_COMPILER_ID:GNU>:-O3> # Host optimize-level
   --verbose
  # --debug # Host debug
  # --device-debug # Device debug
)

set(CMAKE_CUDA_FLAGS_DEBUG "--optimize 0 --debug --device-debug -g -G")
set(CMAKE_CUDA_FLAGS_RELEASE "--optimize 3")

####################################################
############ TARGET COMPILE OPTIONS ################
####################################################


if("${HIP_BACKEND_CUDA}" STREQUAL "1")
target_compile_options(essentials INTERFACE 
  $<$<COMPILE_LANGUAGE:CXX>:${CXX_FLAGS}>
  $<$<COMPILE_LANGUAGE:CUDA>:${CUDA_FLAGS}>
)
else()
target_compile_options(essentials INTERFACE 
  $<$<COMPILE_LANGUAGE:CXX>:${CXX_FLAGS}>
  $<$<COMPILE_LANGUAGE:HIP>:${HIP_FLAGS}>
)

endif()

####################################################
############ BUILD EXAMPLE APPLICATIONS ############
####################################################
option(ESSENTIALS_BUILD_EXAMPLES
  "If on, builds the example graph applications."
  ON)

# Subdirectories for examples, testing and documentation
if(ESSENTIALS_BUILD_EXAMPLES)
  add_subdirectory(examples)
endif(ESSENTIALS_BUILD_EXAMPLES)

####################################################
################ BUILD UNIT TESTS  #################
####################################################
option(ESSENTIALS_BUILD_TESTS
  "If on, builds the unit tests."
  ON)

# Subdirectories for examples, testing and documentation
if(ESSENTIALS_BUILD_TESTS)
  include(${PROJECT_SOURCE_DIR}/cmake/FetchGoogleTest.cmake)
  enable_testing()
  #add_subdirectory(unittests)
endif(ESSENTIALS_BUILD_TESTS)

####################################################
################ BUILD BENCHMARKS  #################
####################################################
option(ESSENTIALS_BUILD_BENCHMARKS
  "If on, builds essentials with benchmarking support."
  OFF)

# Subdirectories for examples, testing and documentation
if(ESSENTIALS_BUILD_BENCHMARKS)
  # ... see https://github.com/NVIDIA/nvbench/issues/66
  set(NVBench_ENABLE_NVML OFF)
  # ... set cuda architecture for nvbench.
  set(CMAKE_CUDA_ARCHITECTURES ${ESSENTIALS_ARCHITECTURES})
  include(${PROJECT_SOURCE_DIR}/cmake/FetchNVBench.cmake)
  add_subdirectory(benchmarks)
endif(ESSENTIALS_BUILD_BENCHMARKS)
