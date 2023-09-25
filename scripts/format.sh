#!/usr/bin/env bash

source scripts/utilities.sh

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

# Check for --apply argument
apply_fixes=false
if [[ $1 == "--apply" ]]; then
  apply_fixes=true
fi

# Run clang-format checking or applying on the discovered files
if $apply_fixes; then
  print_color "yellow" "🔎 Applying clang-format..."
else
  print_color "yellow" "🔎 Running clang-format check..."
fi

clang_format_result=""
for file in $cpp_files; do
  if $apply_fixes; then
    clang-format -style=file -i "$file"
    echo -e "\t✅ $file"
  else
    result=$(clang-format -style=file -output-replacements-xml "$file" | grep "<replacement " || true)
    if [[ $result ]]; then
      echo -e "\t❌ $file"
      clang_format_result="$clang_format_result"$'\n'"❌ $file"
    else
      echo -e "\t✅ $file"
    fi
  fi
done

if [[ $clang_format_result ]]; then
  num_failed_files=$(echo -e "$clang_format_result" | wc -l | bc)
  print_color "red" "🚫 clang-format check failed on $num_failed_files files"
  exit 1
else
  print_color "green" "✅ clang-format check passed."
fi
echo ""
