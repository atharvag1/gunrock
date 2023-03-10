# begin /* Set the application name. */
set(APPLICATION_NAME pr)
# end /* Set the application name. */

# begin /* Add CUDA executables */
add_executable(${APPLICATION_NAME})

set(SOURCE_LIST 
    ${APPLICATION_NAME}.cu
)

target_sources(${APPLICATION_NAME} PRIVATE ${SOURCE_LIST})
target_link_libraries(${APPLICATION_NAME} PRIVATE essentials)
if("$ENV{HIP_PLATFORM}" STREQUAL "nvidia")
get_target_property(ESSENTIALS_ARCHITECTURES essentials CUDA_ARCHITECTURES)
set_target_properties(${APPLICATION_NAME} 
    PROPERTIES 
        CUDA_ARCHITECTURES ${ESSENTIALS_ARCHITECTURES}
) # XXX: Find a better way to inherit essentials properties.

message(STATUS "Example Added: ${APPLICATION_NAME}")


else()
get_target_property(ESSENTIALS_ARCHITECTURES essentials HIP_ARCHITECTURES)
set_target_properties(${APPLICATION_NAME} 
    PROPERTIES 
        HIP_ARCHITECTURES ${ESSENTIALS_ARCHITECTURES}
) # XXX: Find a better way to inherit essentials properties.
set_source_files_properties( ${APPLICATION_NAME} PROPERTIES LANGUAGE HIP)
message(STATUS "Example Added: ${APPLICATION_NAME}")
endif()
# end /* Add CUDA executables */
