#!/usr/bin/env sh
print_color() {
  local color=$1
  local message=$2
  case "$color" in
    "red")
      printf "\e[31m%s\e[0m\n" "$message"
      ;;
    "green")
      printf "\e[32m%s\e[0m\n" "$message"
      ;;
    "blue")
      printf "\e[34m%s\e[0m\n" "$message"
      ;;
    *)
      printf "%s\n" "$message"
      ;;
  esac
}

exit_on_failure() {
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    print_color "red" "❌ Operation failed with exit code $exit_code."
    exit 1
  else
    print_color "green" "✅ Operation succeeded."
  fi
}

if [ ! -d "build" ]; then
  print_color "blue" "🔨 Creating build directory..."
  mkdir build
  exit_on_failure
fi
cd build

print_color "blue" "🔨 Removing old fstl executable..."
rm ./fstl.app/Contents/MacOS/fstl

print_color "blue" "🔨 Running cmake..."
cmake -DCMAKE_PREFIX_PATH=/usr/local/Cellar/qt/5.15.0/ ..
exit_on_failure

print_color "blue" "🔨 Running make..."
make -j8
exit_on_failure

cd ..

print_color "blue" "🔨 Running fstl..."
./build/fstl.app/Contents/MacOS/fstl ~/Desktop/3DFiles/LegoMan.step
exit_on_failure




