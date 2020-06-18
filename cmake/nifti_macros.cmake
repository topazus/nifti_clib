macro(set_if_not_defined var defaultvalue)
# Macro allowing to set a variable to its default value if not already defined.
# The default value is set with:
#  (1) if set, the value environment variable <var>.
#  (2) if set, the value of local variable variable <var>.
#  (3) if none of the above, the value passed as a parameter.
# Setting the optional parameter 'OBFUSCATE' will display 'OBFUSCATED' instead of the real value.
  set(_obfuscate FALSE)
  foreach(arg ${ARGN})
    if(arg STREQUAL "OBFUSCATE")
      set(_obfuscate TRUE)
    endif()
  endforeach()
  if(DEFINED ENV{${var}} AND NOT DEFINED ${var})
    set(_value "$ENV{${var}}")
    if(_obfuscate)
      set(_value "OBFUSCATED")
    endif()
    message(STATUS "Setting '${var}' variable with environment variable value '${_value}'")
    set(${var} $ENV{${var}})
  endif()
  if(NOT DEFINED ${var})
    set(_value "${defaultvalue}")
    if(_obfuscate)
      set(_value "OBFUSCATED")
    endif()
    message(STATUS "Setting '${var}' variable with default value '${_value}'")
    set(${var} "${defaultvalue}")
  endif()
endmacro()

function(add_nifti_library target_in)
    add_library(${ARGV})
    add_library(NIFTI::${target_in} ALIAS ${target_in})
    if(NOT NIFTI_INSTALL_NO_LIBRARIES)
      get_property(tmp GLOBAL PROPERTY nifti_installed_targets)
      list(APPEND tmp "${target_in}")
      set_property(GLOBAL PROPERTY nifti_installed_targets "${tmp}")
    endif()
endfunction()

function(add_nifti_executable target_in)
  add_executable(${ARGV})
  if(NOT NIFTI_INSTALL_NO_APPLICATIONS)
    get_property(tmp GLOBAL PROPERTY nifti_installed_targets)
    list(APPEND tmp "${target_in}")
    set_property(GLOBAL PROPERTY nifti_installed_targets "${tmp}")
  endif()
endfunction()

function(install_nifti_target target_name)
  # Check if the current directory is the base directory of the project
  if("${PROJECT_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_LIST_DIR}")
    set(IS_PROJECT_DIR 1)
  else()
    set(IS_PROJECT_DIR 0)
  endif()

  if(NOT CMAKE_VER_AT_LEAST_3_13 AND IS_PROJECT_DIR)
    # Early version of CMake so installation must happen in the directory in
    # which the target is defined. No installation occurs from the project
    # directory
    return()
  elseif(CMAKE_VER_AT_LEAST_3_13 AND NOT IS_PROJECT_DIR)
    # CMake >=3.13 has support for referencing targets in parent scopes of the
    # one in which the target is defined. This enables a central management of
    # the installation process, along with installating an target export set.
    # No installation occurs from the directory in which the target is defined
    return()
  endif()

  # Install the targets now that the appropriate directory is confirmed.
  if(NIFTI_INSTALL_NO_DEVELOPMENT)
    install(TARGETS ${target_name}
            EXPORT ${NIFTI_INSTALL_EXPORT_NAME}
            RUNTIME
              COMPONENT RuntimeBinaries
              DESTINATION ${NIFTI_INSTALL_RUNTIME_DIR}
            ARCHIVE
              DESTINATION ${NIFTI_INSTALL_LIBRARY_DIR}
              COMPONENT RuntimeLibraries
            LIBRARY
              DESTINATION ${NIFTI_INSTALL_LIBRARY_DIR}
              COMPONENT RuntimeLibraries
            )
  else()
    install(TARGETS ${target_name}
            EXPORT ${NIFTI_INSTALL_EXPORT_NAME}
            RUNTIME
              COMPONENT RuntimeBinaries
              DESTINATION ${NIFTI_INSTALL_RUNTIME_DIR}
            ARCHIVE
              DESTINATION ${NIFTI_INSTALL_LIBRARY_DIR}
              COMPONENT RuntimeLibraries
            LIBRARY
              DESTINATION ${NIFTI_INSTALL_LIBRARY_DIR}
              COMPONENT RuntimeLibraries
            PUBLIC_HEADER
              DESTINATION ${NIFTI_INSTALL_INCLUDE_DIR}
            INCLUDES
              DESTINATION ${NIFTI_INSTALL_INCLUDE_DIR}
            )
    endif()
endfunction()


function(get_lib_version_vars version_header libver libver_major)
    # Function reads a file containing the lib version and sets the
    # approprioate variables in the parent scope
    file(READ ${version_header} VER_FILE)
    string(REGEX MATCHALL "(_MAJOR|_MINOR|_PATCH) ([0-9]*)" VER_MATCHES ${VER_FILE})
    string(REGEX REPLACE "(_MAJOR |_MINOR |_PATCH )" "" VER_MATCHES ${VER_MATCHES})
    string(SUBSTRING ${VER_MATCHES} 0 1 LIB_MAJOR_VERSION )
    string(SUBSTRING ${VER_MATCHES} 1 1 LIB_MINOR_VERSION )
    string(SUBSTRING ${VER_MATCHES} 2 1 LIB_PATCH_VERSION )
    set(LIB_VERSION "${LIB_MAJOR_VERSION}.${LIB_MINOR_VERSION}.${LIB_PATCH_VERSION}")

    # Check that a valid version has been specified (of the form XX.XX.XX)
    string(REGEX MATCH "^[0-9]*\.[0-9]*\.[0-9]*$" VER_MATCHED "${LIB_VERSION}" )
    if("" STREQUAL "${VER_MATCHED}")
        message("matched ${VER_MATCHED}")
        message(FATAL_ERROR "Cannot find a valid version in the version header file ${version_header} (Found: '${LIB_VERSION}')")
    endif()
    # Set outputs in calling scope
    set(${libver} "${LIB_VERSION}" PARENT_SCOPE)
    set(${libver_major} "${LIB_MAJOR_VERSION}" PARENT_SCOPE)
endfunction()