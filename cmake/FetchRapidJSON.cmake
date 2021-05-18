include(FetchContent)
set(FETCHCONTENT_QUIET ON)

message("-- Cloning External Project: RapidJSON")
get_filename_component(FC_BASE "../externals"
                REALPATH BASE_DIR "${CMAKE_BINARY_DIR}")
set(FETCHCONTENT_BASE_DIR ${FC_BASE})

FetchContent_Declare(
    rapidjson
    GIT_REPOSITORY https://github.com/Tencent/rapidjson.git
    GIT_TAG        v1.1.0
)

FetchContent_GetProperties(rapidjson)
if(NOT rapidjson_POPULATED)
  FetchContent_Populate(
    rapidjson
  )
endif()
set(RAPIDJSON_INCLUDE_DIR "${rapidjson_SOURCE_DIR}/include")