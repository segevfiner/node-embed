include(SelectLibraryConfigurations)
include(FindPackageHandleStandardArgs)

set(Node_ROOT CACHE PATH "Built Node.js root.")
set(Node_ABI ${Node_ABI_DEFAULT} CACHE STRING "Nobe ABI version.")

if(NOT WIN32)
    if(NOT Node_ABI)
        message(FATAL_ERROR "Please set Node_ABI")
    endif()
    find_path(Node_INCLUDE_DIR node_api.h PATH_SUFFIXES node)
    find_library(Node_LIBRARY_RELEASE node.${Node_ABI})
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
    endif()
    if (Node_LIBRARY_DEBUG)
        set_property(TARGET Node::Node APPEND PROPERTY
            IMPORTED_CONFIGURATIONS DEBUG
        )
        set_target_properties(Node::Node PROPERTIES
            IMPORTED_LOCATION_DEBUG "${Node_LIBRARY_DEBUG}"
        )
    endif()
    set_target_properties(Node::Node PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${Node_INCLUDE_DIR}"
    )
endif()

mark_as_advanced(
    Node_INCLUDE_DIR
)
