#!/usr/bin/env bash

##############################################################################
# Helper Methods
##############################################################################
print_in_green() {
    echo -e "\e[32m$1\e[0m"
}

print_in_yellow() {
    echo -e "\e[33m$1\e[0m"
}

print_package_info() {
    local package=$1
    local command=${2:-$1}
    local location=$(which $command 2> /dev/null)
    if [ -z "$location" ]; then
        # If the command is not found, check if it's a library
        local version=$(dpkg-query -W -f='${Version}' $package 2> /dev/null)
        if [ -z "$version" ]; then
            echo -e "\e[31m❌ Could not find installation path for $package.\e[0m"
            exit 1
        else
            echo -e "\e[32m✅ Found $package installed with version: $version.\e[0m"
            echo $version
        fi
    else
        echo -e "\e[32m✅ Found installation path for $package: $location.\e[0m"
        echo $location
    fi
}

exit_on_failure() {
    local exit_code=$?
    local message=$1
    if [ $exit_code -ne 0 ]; then
        print_in_red "❌ $message failed."
        exit $exit_code
    else
        print_in_green "✅ $message succeeded."
        echo "" 
    fi
}

print_in_red() {
    echo -e "\e[31m$1\e[0m"
}

search_for_file() {
    local filename=$1
    local likely_locations=("/usr/local/lib/opencascade/cmake/opencascade" "/usr/local/Cellar/opencascade/7.7.2_1/lib/cmake/opencascade")
    local result=""

    # First, search in the likely locations
    for location in "${likely_locations[@]}"; do
        if [ -f "$location/$filename" ]; then
            result="$location/$filename"
            break
        fi
    done

    # If not found in the likely locations, perform an exhaustive search
    if [ -z "$result" ]; then
        result=$(find / -name $filename 2>/dev/null)
    fi

    if [ -z "$result" ]; then
        echo -e "\e[31m❌ Could not find $filename.\e[0m"
        exit 1
    else
        echo $result
    fi
}

install_deps_linux() {
    sudo apt-get install -y clang-format qtbase5-dev liboce-modeling-dev liboce-ocaf-dev libvtk7-dev
    exit_on_failure "Installing dependencies"

    local opencascade_config_path=$(search_for_file "OpenCASCADEConfig.cmake")
    local opencascade_dir=$(dirname "$opencascade_config_path")
    export OpenCASCADE_DIR=$opencascade_dir
    echo "🗂️ OpenCASCADE_DIR set to $OpenCASCADE_DIR"

    local vtk_config_path=$(search_for_file "VTKConfig.cmake")
    local vtk_dir=$(dirname "$vtk_config_path")
    export VTK_DIR=$vtk_dir
    echo "🗂️ VTK_DIR set to $VTK_DIR"
    print_in_green "✅ Environment variables set for Linux"
}

install_deps_mac() {
    brew install clang-format
    # Set environment variables for MacOS
    export PATH="/usr/local/opt/qt/bin:$PATH"
    export CMAKE_PREFIX_PATH="/usr/local/opt/qt"
    export CMAKE_PREFIX_PATH="/usr/local/Cellar/opencascade/7.7.2_1:$CMAKE_PREFIX_PATH"
    export Qt5_DIR=/usr/local/Cellar/qt@5/5.15.10_1/lib/cmake/Qt5
    export OpenCASCADE_DIR=/usr/local/Cellar/opencascade/7.7.2_1/lib/cmake/opencascade
    print_in_green "✅ Environment variables set for MacOS"
}

install_deps_windows() {
    echo "Unsupported architecture: $OSTYPE"
    exit 1
}

##############################################################################
# Main
##############################################################################

print_in_yellow "🚧 Setting up development for BuildOS Viewer..."
echo ""

print_in_yellow "🔧 Installing dependencies..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    install_deps_linux
elif [[ "$OSTYPE" == "darwin"* ]]; then
    install_deps_mac
else
    install_deps_windows
fi
echo ""

print_in_green "✅ Development is now set up!"
