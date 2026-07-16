cmake_minimum_required(VERSION 3.16)
project(module1_transmon_edep LANGUAGES CXX)

# Geant4 11.x requires C++17.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# UI and visualization are required because this application is intended to be
# launched interactively while the particle gun is configured with /gun/* commands.
find_package(Geant4 REQUIRED ui_all vis_all)
include(${Geant4_USE_FILE})

file(GLOB sources CONFIGURE_DEPENDS ${PROJECT_SOURCE_DIR}/src/*.cc)
file(GLOB headers CONFIGURE_DEPENDS ${PROJECT_SOURCE_DIR}/include/*.hh)

add_executable(module1_transmon_edep ${sources} ${headers})
target_include_directories(module1_transmon_edep PRIVATE ${PROJECT_SOURCE_DIR}/include)
target_link_libraries(module1_transmon_edep PRIVATE ${Geant4_LIBRARIES})

foreach(_script
  init_vis.mac
  vis_run.mac
  run_batch.mac
  geometry_check.mac
)
  configure_file(${PROJECT_SOURCE_DIR}/macros/${_script}
                 ${PROJECT_BINARY_DIR}/${_script}
                 COPYONLY)
endforeach()

file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/output)
