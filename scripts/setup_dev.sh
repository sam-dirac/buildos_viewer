#!/usr/bin/env bash

source scripts/utilities.sh

##############################################################################
# Helper Methods
##############################################################################

search_for_file() {
    local filename=$1
    shift
    local likely_locations=("$@")
    local result=""
    print_color "yellow" "🔍 Searching for file '$filename'..."
    for location in ${likely_locations[@]}; do
        print_color "yellow" "📍 Checking location: $location"
    done
    echo ""

    # First, search in the likely locations
    for location in "${likely_locations[@]}"; do
        result=$(find "$location" -name "$filename" 2>/dev/null)
        if [ -n "$result" ]; then
            break
        fi
    done

    if [ -n "$result" ]; then
        print_color "green" "✔️  File found at: $result"
        return
    fi
    

    # If the file was not found in the likely locations, fall back to an exhaustive search
    if [ -z "$result" ]; then
        result=$(find / -name "$filename" 2>/dev/null)
        # Debugging the exhaustive search
        if [ -z "$result" ]; then
            print_color "red" "❌ Exhaustive search failed to find the file."
        else
            print_color "green" "✔️  Exhaustive search found the file at: $result"
        fi
    fi

    if [ -z "$result" ]; then
        printf "\033[31m❌ Could not find %s.\033[0m\n" "$filename"
        exit 1
    else
        echo $result
    fi
}

uninstall_deps_linux() {
    brew uninstall opencascade
    exit_on_failure "Uninstalling dependencies"
}

install_deps_linux() {
    if brew ls --versions opencascade > /dev/null; then
        print_color "green" "✅ OpenCASCADE is already installed"
    else
        brew install opencascade
        exit_on_failure "Installing OpenCASCADE"
    fi
    # Search for a cmake config file for Open Cascade
    search_for_file "OpenCASCADEConfig.cmake" "/home/linuxbrew/.linuxbrew/Cellar/opencascade"
    exit_on_failure "Searching for OpenCASCADEConfig.cmake"

    sudo apt-get install -y clang-format qtbase5-dev
    exit_on_failure "Installing dependencies"
}

install_deps_mac() {
    brew install clang-format
    # Set environment variables for MacOS
    export PATH="/usr/local/opt/qt/bin:$PATH"
    export CMAKE_PREFIX_PATH="/usr/local/opt/qt"
    export CMAKE_PREFIX_PATH="/usr/local/Cellar/opencascade/7.7.2_1:$CMAKE_PREFIX_PATH"
    export Qt5_DIR=/usr/local/Cellar/qt@5/5.15.10_1/lib/cmake/Qt5
    export OpenCASCADE_DIR=/usr/local/Cellar/opencascade/7.7.2_1/lib/cmake/opencascade
    print_color "green" "✅ Environment variables set for MacOS"
}

install_deps_windows() {
    printf "Unsupported architecture: %s\n" "$OSTYPE"
    exit 1
}

##############################################################################
# Main
##############################################################################
print_color "yellow" "🚧 Setting up development for BuildOS Viewer..."
echo ""
if [[ -z "$1" ]]; then
    print_color "yellow" "🔧 Installing dependencies..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        install_deps_linux
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        install_deps_mac
    else
        install_deps_windows
    fi
    echo ""
    print_color "green" "✅ Installation is now complete!"
    exit 0
elif [[ "$1" == "--help" ]]; then
    echo "Usage: setup_dev.sh [OPTION]"
    echo "Setup development environment for BuildOS Viewer."
    echo ""
    echo "Options:"
    echo "--uninstall    Uninstall dependencies"
    echo "--help         Display this help and exit"
    exit 0
elif [[ "$1" == "--uninstall" ]]; then
    print_color "yellow" "🔧 Uninstalling dependencies..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        uninstall_deps_linux
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        uninstall_deps_mac
    else
        uninstall_deps_windows
    fi
    echo ""
    print_color "green" "✅ Uninstallation is now complete!"
    exit 0
else
    echo "Invalid option: $1"
    echo "Try 'setup_dev.sh --help' for more information."
    exit 1
fi

print_color "green" "✅ Development is now set up!"


