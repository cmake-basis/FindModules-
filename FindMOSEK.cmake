##############################################################################
# @file  FindMOSEK.cmake
# @brief Find MOSEK (http://www.mosek.com) package.
#
# @par Input variables:
# <table border="0">
#   <tr>
#     @tp @b MOSEK_DIR @endtp
#     <td>The MOSEK package files are searched under the specified root
#         directory. If they are not found there, the default search paths
#         are considered. This variable can also be set as environment variable.</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_NO_OMP @endtp
#     <td>Whether to use the link libraries build without OpenMP, i.e.,
#         multi-threading, enabled. By default, the multi-threaded libraries
#         are used.</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_MATLAB @endtp
#     <td>Whether the MATLAB components of the MOSEK packages should be found.
#         Defaults to 1, if @c MATLAB_FOUND evaluates to true and 0 otherwise.</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_JAVA @endtp
#     <td>Whether the Java components of the MOSEK package should be found.
#         Defaults to 0.</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_PYTHON @endtp
#     <td>Whether the Python components of the MOSEK package should be found.
#         Defaults to 0.</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_TOOLS_SUFFIX @endtp
#     <td>Platform specific path suffix for tools, i.e., "tools/platform/linux64x86"
#         on 64-bit Linux systems. If not specified, this module determines the
#         right suffix depending on the CMake system variables.</td>
#   </tr>
#   <tr>
#     @tp @b MATLAB_RELEASE @endtp
#     <td>Release of MATLAB installation. Set to the 'Release' return value of
#         the "ver ('MATLAB')" command of MATLAB without brackets. If this
#         variable is not set and the basis_get_matlab_release() command is
#         available, it is invoked to determine the release version automatically.
#         Otherwise, the release version defaults to "R2009b".</td>
#   </tr>
#   <tr>
#     @tp @b MEX_EXT @endtp
#     <td>The extension of MEX-files. If this variable is not set and the
#         basis_mexext() command is available, it is invoked to determine the
#         extension automatically. Otherwise, the MEX extension defaults to "mexa64".</td>
#   </tr>
#   <tr>
#     @tp @b PYTHON_VERSION @endtp
#     <td>Version of Python installation. Set to first two or three return values of
#         "sys.version_info" separated by a period (.). If this variable is not set
#         and the basis_get_python_version() command is available, it is invoked to
#         determine the version automatically. Otherwise, the Python version
#         defaults to 2.6.</td>
#   </tr>
# </table>
#
# @par Output variables:
# <table border="0">
#   <tr>
#     @tp @b MOSEK_FOUND @endtp
#     <td>Whether the package was found and the following CMake variables are valid.</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_INCLUDE_DIR @endtp
#     <td>Package include directories.</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_INCLUDES @endtp
#     <td>Include directories including prerequisite libraries (non-cached).</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_LIBRARY @endtp
#     <td>Package libraries.</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_LIBRARIES @endtp
#     <td>Package libraries and prerequisite libraries (non-cached).</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_mosekopt_MEX @endtp
#     <td>Package mosekopt MEX-file.</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_MEX_FILES @endtp
#     <td>List of MEX-files (non-cached).</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_mosek_JAR @endtp
#     <td>Package mosek Java library (.jar file).</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_CLASSPATH @endtp
#     <td>List of Java package libraries and prerequisite libraries (non-cached).</td>
#   </tr>
#   <tr>
#     @tp @b MOSEK_PYTHONPATH @endtp
#     <td>Path to Python modules of this package.</td>
#   </tr>
# </table>
#
# Copyright (c) 2011-2012, University of Pennsylvania. All rights reserved.<br />
# See http://www.rad.upenn.edu/sbia/software/license.html or COPYING file.
#
# Contact: SBIA Group <sbia-software at uphs.upenn.edu>
#
# @ingroup CMakeFindModules
##############################################################################

# ----------------------------------------------------------------------------
# initialize search
if (NOT MOSEK_DIR)
  set (MOSEK_DIR "$ENV{MOSEK_DIR}" CACHE PATH "Installation prefix for MOSEK." FORCE)
endif ()

# MATLAB components
if (NOT DEFINED MOSEK_MATLAB)
  set (MOSEK_MATLAB ${MATLAB_FOUND})
endif ()

if (MOSEK_MATLAB)
  # MATLAB version
  if (NOT MATLAB_RELEASE)
    if (COMMAND basis_get_matlab_release)
      basis_get_matlab_release ()
      if (NOT MATLAB_RELEASE)
        message (FATAL_ERROR "Failed to determine release version of MATLAB installation. "
                             "This information is required to be able to find the right MOSEK MEX-files. "
                             "Set MATLAB_RELEASE manually and try again.")
      endif ()
    else ()
      set (MATLAB_RELEASE "R2009b")
    endif ()
  endif ()
  string (TOLOWER "${MATLAB_RELEASE}" MATLAB_RELEASE_LOWER)
  # search path for MOSEK MATLAB toolbox
  if (NOT MOSEK_TOOLBOX_SUFFIX)
    if (MOSEK_DIR)
      file (
        GLOB_RECURSE
          MOSEK_TOOLBOX_SUFFIXES
        RELATIVE "${MOSEK_DIR}"
        "${MOSEK_DIR}/toolbox/*/*.mex*"
      )
      set (MOSEK_TOOLBOX_VERSIONS)
      foreach (MOSEK_MEX_FILE IN LISTS MOSEK_TOOLBOX_SUFFIXES)
        get_filename_component (MOSEK_TOOLBOX_SUFFIX  "${MOSEK_MEX_FILE}" PATH)
        get_filename_component (MOSEK_TOOLBOX_VERSION "${MOSEK_TOOLBOX_SUFFIX}" NAME)
        list (APPEND MOSEK_TOOLBOX_VERSIONS "${MOSEK_TOOLBOX_VERSION}")
        set (MOSEK_TOOLBOX_SUFFIX)
      endforeach ()
      list (SORT MOSEK_TOOLBOX_VERSIONS)
      list (REVERSE MOSEK_TOOLBOX_VERSIONS)
      string (REGEX MATCH "[0-9][0-9]*" MATLAB_RELEASE_YEAR "${MATLAB_RELEASE}")
      foreach (MOSEK_TOOLBOX_VERSION IN LISTS MOSEK_TOOLBOX_VERSIONS)
        if (MOSEK_TOOLBOX_VERSION MATCHES "[rR]([0-9][0-9]*)[ab]")
          if (CMAKE_MATCH_1 EQUAL MATLAB_RELEASE_VERSION OR
              CMAKE_MATCH_1 LESS  MATLAB_RELEASE_VERSION)
            set (MATLAB_TOOLBOX_SUFFIX "toolbox/${MOSEK_TOOLBOX_VERSION}")
            break ()
          endif ()
        endif ()
      endforeach ()
    endif ()
    if (NOT MOSEK_TOOLBOX_SUFFIX)
      set (MOSEK_TOOLBOX_SUFFIX "toolbox/${MATLAB_RELEASE_LOWER}")
    endif ()
  endif ()
  # extension of MEX-files
  if (NOT MEX_EXT)
    if (COMMAND basis_mexext)
      basis_mexext ()
    else ()
      set (MEX_EXT "mexa64")
    endif ()
  endif ()
endif ()

# Java components
if (NOT DEFINED MOSEK_JAVA)
  set (MOSEK_JAVA 0)
endif ()

# Python components
if (NOT DEFINED MOSEK_PYTHON)
  set (MOSEK_PYTHON 0)
endif ()

if (MOSEK_PYTHON)
  # Python version
  if (NOT PYTHON_VERSION)
    if (COMMAND basis_get_python_version)
      basis_get_python_version ()
      if (NOT PYTHON_VERSION)
        message (FATAL_ERROR "Failed to determine version of Python installation. "
                             "This information is required to be able to find the right MOSEK Python modules. "
                             "Set PYTHON_VERSION manually and try again.")
      endif ()
    else ()
      set (PYTHON_VERSION "2.6")
    endif ()
  endif ()
  # major version of Python
  string (REGEX REPLACE "^([0-9]+)" "\\1" PYTHON_VERSION_MAJOR "${PYTHON_VERSION}")
endif ()

# library name
set (MOSEK_LIBRARY_NAME "mosek")
if (MOSEK_NO_OMP)
  set (MOSEK_LIBRARY_NAME "${MOSEK_LIBRARY_NAME}noomp")
endif ()
if (UNIX)
  if (NOT CMAKE_SIZE_OF_VOID_P EQUAL 4)
    set (MOSEK_LIBRARY_NAME "${MOSEK_LIBRARY_NAME}64")
  endif ()
endif ()
set (MOSEK_LIBRARY_NAMES "${MOSEK_LIBRARY_NAME}")
if (WIN32)
  foreach (VERSION_SUFFIX "6_0")
    list (APPEND MOSEK_LIBRARY_NAMES "${MOSEK_LIBRARY_NAME}${VERSION_SUFFIX}")
  endforeach ()
endif ()

# search path for MOSEK tools
if (NOT MOSEK_TOOLS_SUFFIX)
  set (MOSEK_TOOLS_SUFFIX "tools/platform/")
  if (WIN32)
    set (MOSEK_TOOLS_SUFFIX "${MOSEK_TOOLS_SUFFIX}win")
  elseif (APPLE)
    set (MOSEK_TOOLS_SUFFIX "${MOSEK_TOOLS_SUFFIX}osx")
  else ()
    set (MOSEK_TOOLS_SUFFIX "${MOSEK_TOOLS_SUFFIX}linux")
  endif ()
  if (CMAKE_SIZE_OF_VOID_P EQUAL 4)
    set (MOSEK_TOOLS_SUFFIX "${MOSEK_TOOLS_SUFFIX}32")
  else ()
    set (MOSEK_TOOLS_SUFFIX "${MOSEK_TOOLS_SUFFIX}64")
  endif ()
  set (MOSEK_TOOLS_SUFFIX "${MOSEK_TOOLS_SUFFIX}x86")
endif ()

#-------------------------------------------------------------
# find paths/files
if (MOSEK_DIR)

  find_path (
    MOSEK_INCLUDE_DIR
      NAMES         mosek.h
      HINTS         "${MOSEK_DIR}"
      PATH_SUFFIXES "${MOSEK_TOOLS_SUFFIX}/h"
      DOC           "Include directory for MOSEK libraries."
      NO_DEFAULT_PATH
  )

  find_library (
    MOSEK_LIBRARY
      NAMES         ${MOSEK_LIBRARY_NAMES}
      HINTS         "${MOSEK_DIR}"
      PATH_SUFFIXES "${MOSEK_TOOLS_SUFFIX}/bin"
      DOC           "MOSEK link library."
      NO_DEFAULT_PATH
  )

else ()

  find_path (
    MOSEK_INCLUDE_DIR
      NAMES mosek.h
      HINTS ENV C_INCLUDE_PATH ENV CXX_INCLUDE_PATH
      DOC   "Include directory for MOSEK libraries."
  )

  find_library (
    MOSEK_LIBRARY
      NAMES ${MOSEK_LIBRARY_NAMES}
      HINTS ENV LD_LIBRARY_PATH
      DOC   "MOSEK link library."
  )

endif ()

mark_as_advanced (MOSEK_INCLUDE_DIR)
mark_as_advanced (MOSEK_LIBRARY)

# MATLAB components
if (MOSEK_MATLAB)
  if (MOSEK_DIR)

    find_file (
      MOSEK_mosekopt_MEX
        NAMES         mosekopt.${MEX_EXT}
        HINTS         "${MOSEK_DIR}"
        PATH_SUFFIXES "${MOSEK_TOOLBOX_SUFFIX}"
        DOC           "The mosekopt MEX-file of the MOSEK package."
        NO_DEFAULT_PATH
    )

  else ()

    find_file (
      MOSEK_mosekopt_MEX
        NAMES         mosekopt.${MEX_EXT}
        PATH_SUFFIXES "${MOSEK_TOOLBOX_SUFFIX}"
        DOC           "The mosekopt MEX-file of the MOSEK package."
    )

  endif ()

  if (MOSEK_mosekopt_MEX)
    set (MOSEK_MEX_FILES "${MOSEK_mosekopt_MEX}")
  endif ()

  mark_as_advanced (MOSEK_mosekopt_MEX)
endif ()

# Java components
if (MOSEK_JAVA)
  if (MOSEK_DIR)

    find_file (
      MOSEK_mosek_JAR
        NAMES         mosek.jar
        HINTS         "${MOSEK_DIR}"
        PATH_SUFFIXES "${MOSEK_TOOLS_SUFFIX}/bin"
        DOC           "The Java library (.jar file) of the MOSEK package."
        NO_DEFAULT_PATH
    )

  else ()

    find_file (
      MOSEK_mosek_JAR
        NAMES mosek.jar
        HINTS ENV CLASSPATH
        DOC   "The Java library (.jar file) of the MOSEK package."
    )

  endif ()

  if (MOSEK_mosek_JAR)
    set (MOSEK_CLASSPATH "${MOSEK_mosek_JAR}")
  endif ()

  mark_as_advanced (MOSEK_mosek_JAR)
endif ()

# Python components
if (MOSEK_PYTHON)
  if (MOSEK_DIR)

    find_path (
      MOSEK_PYTHONPATH
        NAMES "mosek/array.py"
        HINTS ENV PYTHONPATH
        DOC   "Path to MOSEK Python module."
    )

  else ()

    find_path (
      MOSEK_PYTHONPATH
        NAMES "mosek/array.py"
        HINTS "${MOSEK_DIR}/${MOSEK_PATH_SUFFIX}/python/${PYTHON_VERSION_MAJOR}"
        DOC   "Path to MOSEK Python module."
        NO_DEFAULT_PATH
    )

  endif ()

  mark_as_advanced (MOSEK_PYTHONPATH)
endif ()

# ----------------------------------------------------------------------------
# prerequisite libraries
set (MOSEK_INCLUDES  "${MOSEK_INCLUDE_DIR}")
set (MOSEK_LIBRARIES "${MOSEK_LIBRARY}")

# ----------------------------------------------------------------------------
# aliases / backwards compatibility
set (MOSEK_INCLUDE_DIRS "${MOSEK_INCLUDES}")

# ----------------------------------------------------------------------------
# debugging
if (BASIS_DEBUG AND COMMAND basis_dump_variables)
  basis_dump_variables ("${CMAKE_CURRENT_BINARY_DIR}/FindMOSEKVariables.cmake")
endif ()

# ----------------------------------------------------------------------------
# handle the QUIETLY and REQUIRED arguments and set *_FOUND to TRUE
# if all listed variables are found or TRUE
include (FindPackageHandleStandardArgs)

set (MOSEK_REQUIRED_VARS
  MOSEK_INCLUDE_DIR
  MOSEK_LIBRARY
)

if (MOSEK_MATLAB)
  list (APPEND MOSEK_REQUIRED_VARS MOSEK_mosekopt_MEX)
endif ()
if (MOSEK_JAVA)
  list (APPEND MOSEK_REQUIRED_VARS MOSEK_mosek_JAR)
endif ()
if (MOSEK_PYTHON)
  list (APPEND MOSEK_REQUIRED_VARS MOSEK_PYTHONPATH)
endif ()

find_package_handle_standard_args (
  MOSEK
# MESSAGE
    DEFAULT_MSG
# VARIABLES
    ${MOSEK_REQUIRED_VARS}
)

# ----------------------------------------------------------------------------
# set MOSEK_DIR
if (NOT MOSEK_DIR AND MOSEK_FOUND)
  string (REGEX REPLACE "${MOSEK_TOOLS_SUFFIX}/h/?" "" MOSEK_PREFIX "${MOSEK_INCLUDE_DIR}")
  set (MOSEK_DIR "${MOSEK_PREFIX}" CACHE PATH "Installation prefix for MOSEK." FORCE)
  unset (MOSEK_PREFIX)
endif ()