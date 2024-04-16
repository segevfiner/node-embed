include(SelectLibraryConfigurations)
include(FindPackageHandleStandardArgs)

set(Node_ROOT CACHE PATH "Built Node.js root.")
set(Node_ABI ${Node_ABI_DEFAULT} CACHE STRING "Nobe ABI version.")

find_path(Node_INCLUDE_DIR node_api.h PATH_SUFFIXES node)

if(NOT WIN32)
    if(NOT Node_ABI)
        message(FATAL_ERROR "Please set Node_ABI")
    endif()
    find_library(Node_LIBRARY_RELEASE node.${Node_ABI})
else()
    find_library(Node_LIBRARY_RELEASE node)
    cmake_path(GET Node_LIBRARY_RELEASE PARENT_PATH Node_LIBRARY_DIR)
    find_file(Node_DEF_RELEASE node.def HINTS ${Node_LIBRARY_DIR}/Release NO_DEFAULT_PATH)

    find_library(Node_LIBRARY_DEBUG node HINTS ${Node_LIBRARY_DIR}/Debug NO_DEFAULT_PATH)
    find_file(Node_DEF_DEBUG node.def HINTS ${Node_LIBRARY_DIR}/Debug NO_DEFAULT_PATH)
endif()

select_library_configurations(Node)
find_package_handle_standard_args(Node
    REQUIRED_VARS
        Node_INCLUDE_DIR
        Node_LIBRARY
)

if(Node_FOUND)
    add_library(Node::Node UNKNOWN IMPORTED)
    if (Node_LIBRARY_RELEASE)
        set_property(TARGET Node::Node APPEND PROPERTY
            IMPORTED_CONFIGURATIONS RELEASE
        )
        set_target_properties(Node::Node PROPERTIES
            IMPORTED_LOCATION_RELEASE "${Node_LIBRARY_RELEASE}"
        )

        if(WIN32)
            set_target_properties(Node::Node PROPERTIES
                INTERFACE_LINK_OPTIONS "/DEF:${Node_DEF_RELEASE}"
            )
        endif()
    endif()
    if (Node_LIBRARY_DEBUG)
        set_property(TARGET Node::Node APPEND PROPERTY
            IMPORTED_CONFIGURATIONS DEBUG
        )
        set_target_properties(Node::Node PROPERTIES
            IMPORTED_LOCATION_DEBUG "${Node_LIBRARY_DEBUG}"
        )

        if(WIN32)
            set_target_properties(Node::Node PROPERTIES
                INTERFACE_LINK_OPTIONS "/DEF:${Node_DEF_DEBUG}"
            )
        endif()
    endif()
    set_target_properties(Node::Node PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${Node_INCLUDE_DIR}"
    )
    target_compile_features(Node::Node INTERFACE cxx_std_17)
endif()

mark_as_advanced(
    Node_INCLUDE_DIR
)
