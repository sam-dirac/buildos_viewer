#!/usr/bin/env bash

#####################################################
# Helper Methods
#####################################################
print_color() {
  local color=$1
  local message=$2
  case $color in
    "black") printf "\e[30m%s\e[0m\n" "$message" ;;
    "red") printf "\e[31m%s\e[0m\n" "$message" ;;
    "green") printf "\e[32m%s\e[0m\n" "$message" ;;
    "yellow") printf "\e[33m%s\e[0m\n" "$message" ;;
    "blue") printf "\e[34m%s\e[0m\n" "$message" ;;
    "magenta") printf "\e[35m%s\e[0m\n" "$message" ;;
    "cyan") printf "\e[36m%s\e[0m\n" "$message" ;;
    "white") printf "\e[37m%s\e[0m\n" "$message" ;;
    *) printf "%s\n" "$message" ;;
  esac
}

#####################################################
# Main
#####################################################

# Discover all C++ files to format
print_color "yellow" "🔎 Discovering files..."
cpp_file_types=("*.cpp" "*.hpp" "*.h" "*.cc" "*.cxx")
exclude_dirs=("build")

cpp_files=""
for type in "${cpp_file_types[@]}"; do
  while IFS= read -r -d '' file; do
    echo -e "\t$file"
    cpp_files="$cpp_files $file"
  done < <(find . -name "$type" -not \( -path "./${exclude_dirs[0]}/*" -prune \) -print0)
done
num_files=$(echo $cpp_files | wc -w | bc)
print_color "green" "📁 Discovered $num_files files..."
echo ""

# Run clang-format checking on the discovered files
print_color "yellow" "🔎 Running clang-format check..."
clang_format_result=""
for file in $cpp_files; do
  result=$(clang-format -style=file -output-replacements-xml "$file" | grep "<replacement " || true)
  if [[ $result ]]; then
    print_color "red" "❌ $file"
    clang_format_result="$clang_format_result\n❌ $file"
  else
    print_color "green" "✅ $file"
  fi
done

if [[ $clang_format_result ]]; then
  print_color "red" "🚫 clang-format check failed. Please fix the following files: $clang_format_result"
  exit 1
else
  print_color "green" "✅ clang-format check passed."
fi
echo ""
