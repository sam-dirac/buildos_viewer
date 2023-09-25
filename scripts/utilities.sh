#!/usr/bin/env bash

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

exit_on_failure() {
    local exit_code=$?
    local message=$1
    if [ $exit_code -ne 0 ]; then
        print_color "red" "❌ $message failed."
        exit $exit_code
    else
        print_color "green" "✅ $message succeeded."
        echo "" 
    fi
}