macro(EIGEN_REPORT_NOT_FOUND REASON_MSG)
  unset(EIGEN_FOUND)
  unset(EIGEN_INCLUDE_DIRS)
  # Make results of search visible in the CMake GUI if Eigen has not
  # been found so that user does not have to toggle to advanced view.
  mark_as_advanced(CLEAR EIGEN_INCLUDE_DIR)
  # Note <package>_FIND_[REQUIRED/QUIETLY] variables defined by FindPackage()
  # use the camelcase library name, not uppercase.
  if (Eigen_FIND_QUIETLY)
    message(STATUS "Failed to find Eigen - " ${REASON_MSG} ${ARGN})
  elseif (Eigen_FIND_REQUIRED)
    message(FATAL_ERROR "Failed to find Eigen - " ${REASON_MSG} ${ARGN})
  else()
    # Neither QUIETLY nor REQUIRED, use no priority which emits a message
    # but continues configuration and allows generation.
    message("-- Failed to find Eigen - " ${REASON_MSG} ${ARGN})
  endif ()
  return()
endmacro(EIGEN_REPORT_NOT_FOUND)

# Protect against any alternative find_package scripts for this library having
# been called previously (in a client project) which set EIGEN_FOUND, but not
# the other variables we require / set here which could cause the search logic
# here to fail.
unset(EIGEN_FOUND)

# Search user-installed locations first, so that we prefer user installs
# to system installs where both exist.
list(APPEND EIGEN_CHECK_INCLUDE_DIRS
  /usr/local/include
  /usr/local/homebrew/include # Mac OS X
  /opt/local/var/macports/software # Mac OS X.
  /opt/local/include
  /usr/include)
# Additional suffixes to try appending to each search path.
list(APPEND EIGEN_CHECK_PATH_SUFFIXES
  eigen3 # Default root directory for Eigen.
  Eigen/include/eigen3 # Windows (for C:/Program Files prefix) < 3.3
  Eigen3/include/eigen3 ) # Windows (for C:/Program Files prefix) >= 3.3

# Search supplied hint directories first if supplied.
find_path(EIGEN_INCLUDE_DIR
  NAMES Eigen/Core
  PATHS ${EIGEN_INCLUDE_DIR_HINTS}
  ${EIGEN_CHECK_INCLUDE_DIRS}
  PATH_SUFFIXES ${EIGEN_CHECK_PATH_SUFFIXES})

if (NOT EIGEN_INCLUDE_DIR OR
    NOT EXISTS ${EIGEN_INCLUDE_DIR})
  eigen_report_not_found(
    "Could not find eigen3 include directory, set EIGEN_INCLUDE_DIR to "
    "path to eigen3 include directory, e.g. /usr/local/include/eigen3.")
endif (NOT EIGEN_INCLUDE_DIR OR
       NOT EXISTS ${EIGEN_INCLUDE_DIR})

# Mark internally as found, then verify. EIGEN_REPORT_NOT_FOUND() unsets
# if called.
set(EIGEN_FOUND TRUE)

# Extract Eigen version from Eigen/src/Core/util/Macros.h
if (EIGEN_INCLUDE_DIR)
  set(EIGEN_VERSION_FILE ${EIGEN_INCLUDE_DIR}/Eigen/src/Core/util/Macros.h)
  if (NOT EXISTS ${EIGEN_VERSION_FILE})
    eigen_report_not_found(
      "Could not find file: ${EIGEN_VERSION_FILE} "
      "containing version information in Eigen install located at: "
      "${EIGEN_INCLUDE_DIR}.")
  else (NOT EXISTS ${EIGEN_VERSION_FILE})
    file(READ ${EIGEN_VERSION_FILE} EIGEN_VERSION_FILE_CONTENTS)

    string(REGEX MATCH "#define EIGEN_WORLD_VERSION [0-9]+"
      EIGEN_WORLD_VERSION "${EIGEN_VERSION_FILE_CONTENTS}")
    string(REGEX REPLACE "#define EIGEN_WORLD_VERSION ([0-9]+)" "\\1"
      EIGEN_WORLD_VERSION "${EIGEN_WORLD_VERSION}")

    string(REGEX MATCH "#define EIGEN_MAJOR_VERSION [0-9]+"
      EIGEN_MAJOR_VERSION "${EIGEN_VERSION_FILE_CONTENTS}")
    string(REGEX REPLACE "#define EIGEN_MAJOR_VERSION ([0-9]+)" "\\1"
      EIGEN_MAJOR_VERSION "${EIGEN_MAJOR_VERSION}")

    string(REGEX MATCH "#define EIGEN_MINOR_VERSION [0-9]+"
      EIGEN_MINOR_VERSION "${EIGEN_VERSION_FILE_CONTENTS}")
    string(REGEX REPLACE "#define EIGEN_MINOR_VERSION ([0-9]+)" "\\1"
      EIGEN_MINOR_VERSION "${EIGEN_MINOR_VERSION}")

    # This is on a single line s/t CMake does not interpret it as a list of
    # elements and insert ';' separators which would result in 3.;2.;0 nonsense.
    set(EIGEN_VERSION "${EIGEN_WORLD_VERSION}.${EIGEN_MAJOR_VERSION}.${EIGEN_MINOR_VERSION}")
  endif (NOT EXISTS ${EIGEN_VERSION_FILE})
endif (EIGEN_INCLUDE_DIR)

# Set standard CMake FindPackage variables if found.
if (EIGEN_FOUND)
  set(EIGEN_INCLUDE_DIRS ${EIGEN_INCLUDE_DIR})
endif (EIGEN_FOUND)

# Handle REQUIRED / QUIET optional arguments and version.
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Eigen
  REQUIRED_VARS EIGEN_INCLUDE_DIRS
  VERSION_VAR EIGEN_VERSION)

# Only mark internal variables as advanced if we found Eigen, otherwise
# leave it visible in the standard GUI for the user to set manually.
if (EIGEN_FOUND)
  mark_as_advanced(FORCE EIGEN_INCLUDE_DIR)
endif (EIGEN_FOUND)
