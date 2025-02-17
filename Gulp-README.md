# VS Code Build System Changes

## Overview
The build system has been modernized and structured to support multiple platforms and build scenarios. The main changes include:

1. Migration to ES Modules
2. Structured Pipeline Organization
3. Enhanced CLI Support
4. Cross-platform Build Support
5. npm install inside the 2 modules of PearAI after moving them from vscode/extenstions or pearai/extenstions and then npm run gulp vscode-linux-x64

# Fix for compiling on Linux
1. Download / clone pearai-app
2. Continue with regular procedure
3. go to extentions/pearai.pearai.* modules folder and do npm install inside both of them
4. go back to the root directory of the project and do: npm run gulp vscode-linux-x64

## Key Changes

### 1. Gulp Configuration
- The main `gulpfile.js` has been simplified to use ES modules
- Build tasks are now modularized and imported from `./build/gulpfile.js`

### 2. Build Pipeline Structure
The build system is organized into several key areas:

#### CLI Build Support
- Dedicated pipeline configurations for CLI builds
- Support for multiple platforms (Windows, Darwin, Linux, Alpine)
- Rust toolchain integration for CLI components - Reverted back to gulp

#### Platform-Specific Builds
- Separate build configurations for:
  - Alpine Linux
  - Windows
  - macOS (Darwin)
  - Standard Linux - More focused on Linux didn't change anything on other OSs.

#### Build Caching
- Implementation of smart caching mechanisms:
  - Node modules caching
  - Built-in dependencies caching
  - Platform-specific caching

### 3. Module Management
- `.moduleignore` configurations for different platforms:
  - Common modules
  - Windows-specific modules
  - Darwin-specific modules
  - Linux-specific modules

### 4. Build Tools and Dependencies
- Rust toolchain integration
  - Version management (default: 1.81)
  - Cross-platform compilation support
  - Platform-specific target configuration

### 5. Security and Signing
- Implementation of code signing pipelines
- Support for:
  - Windows code signing
  - macOS code signing and notarization
  - ESRP (Microsoft Enterprise Signing) integration

### 6. Cache Management
- Enhanced caching system with:
  - Cache salt management (`.cachesalt`)
  - Computed cache keys for node modules
  - Built-in dependencies cache computation

## Build Pipeline Features

### Automated Builds
- Support for multiple architectures:
  - x64
  - arm64
  - Cross-platform compilation

### Quality Control
- Integration of multiple testing layers:
  - Clippy lint for Rust code
  - Unit testing
  - Build verification

### Asset Management
- Structured artifact handling
- Platform-specific packaging
- Automated signing and verification

## Configuration Files

### Key Configuration Files
- `.npmrc`: NPM configuration with extended timeout and build settings
- `.gitignore`: Build-specific ignore patterns
- `.moduleignore`: Platform-specific module filtering
- `.cachesalt`: Cache invalidation control

## Platform-Specific Considerations

### Windows
- Special handling for Windows-specific modules
- MSVC toolchain integration
- Windows-specific signing process

### macOS
- Darwin-specific module management
- Notarization process
- Platform-specific signing requirements

### Linux
- Alpine Linux support
- Multiple architecture support
- Platform-specific module filtering

## Build Process Improvements

### Performance Optimizations
- Smart caching mechanisms
- Parallel build support
- Optimized dependency management

### Security Enhancements
- Integrated code signing
- Secure build pipelines
- Enterprise signing support

## Development Workflow
1. Build system automatically detects platform
2. Applies appropriate configuration
3. Manages dependencies and caching
4. Executes platform-specific build steps
5. Handles signing and packaging
