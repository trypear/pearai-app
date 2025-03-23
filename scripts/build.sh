#!/bin/bash

# Kill any existing build processes
pkill -f "gulp"

# Clear node modules cache if needed
# rm -rf node_modules
# npm install

# Clean build artifacts
rm -rf out
rm -rf .gulp-cache
rm -rf .gulp-tsbuildinfo

# Set optimization flags
export NODE_ENV=production
export VSCODE_BUILD_STANDALONE=1
export VSCODE_ARCH=x64
export VSCODE_PLATFORM=linux

# Use maximum memory allocation
export NODE_OPTIONS="--max-old-space-size=8192"

# Optional: Disable some development features
export VSCODE_SKIP_TESTS=1
export VSCODE_SKIP_EXTENSIONS=1

# Run optimized build
gulp linux-x64
