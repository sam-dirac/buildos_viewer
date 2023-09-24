
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt-get install clang-format
elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install clang-format
else
    echo "Unsupported architecture: $OSTYPE"
    exit 1
fi
