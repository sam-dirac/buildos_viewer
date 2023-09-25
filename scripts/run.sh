#!/usr/bin/env bash

source scripts/utilities.sh

executable_location() {
  if [ "$(uname)" = "Darwin" ]; then
    echo "./fstl.app/Contents/MacOS/fstl"
  else
    echo "./fstl"
  fi
}

###################################################
# Main
###################################################

if [ ! -d "build" ]; then
  print_color "blue" "🔨 Creating build directory..."
  mkdir build
  exit_on_failure "Making build directory"
fi
cd build

fstl_executable=$(executable_location)

print_color "blue" "🔨 Removing old fstl executable..."
rm $fstl_executable

print_color "blue" "🔨 Running cmake..."
cmake -DCMAKE_PREFIX_PATH=/usr/local/Cellar/qt/5.15.0/ ..
exit_on_failure "CMake"

print_color "blue" "🔨 Running make..."
make -j8
exit_on_failure "Make"

cd ..

print_color "blue" "🔨 Running fstl..."
"./build/$fstl_executable" ~/Desktop/3DFiles/LegoMan.step
exit_on_failure "Execution"




