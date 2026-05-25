cmake_minimum_required(VERSION 3.16)
project(module1_silicon_edep LANGUAGES CXX)

# Geant4 11.x requires C++17.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ui_all and vis_all are requested so the executable links against the UI/visualization
# components in your Geant4 installation, including Qt6/OpenGL if they were enabled.
find_package(Geant4 REQUIRED ui_all vis_all)
include(${Geant4_USE_FILE})

file(GLOB sources CONFIGURE_DEPENDS ${PROJECT_SOURCE_DIR}/src/*.cc)
file(GLOB headers CONFIGURE_DEPENDS ${PROJECT_SOURCE_DIR}/include/*.hh)

add_executable(module1_silicon_edep ${sources} ${headers})
target_include_directories(module1_silicon_edep PRIVATE ${PROJECT_SOURCE_DIR}/include)
target_link_libraries(module1_silicon_edep PRIVATE ${Geant4_LIBRARIES})

# Copy macros into the build directory so they can be run as:
#   ./module1_silicon_edep run_batch.mac
foreach(_script
  run_batch.mac
  init_vis.mac
  vis_run.mac
)
  configure_file(${PROJECT_SOURCE_DIR}/macros/${_script} ${PROJECT_BINARY_DIR}/${_script} COPYONLY)
endforeach()

# Create an output directory in the build folder.
file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/output)
