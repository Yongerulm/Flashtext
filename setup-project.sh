#!/bin/zsh
set -e

echo "Setting up Blitztext Xcode project..."

# Create Xcode project using Swift Package Manager
swift package resolve

# Generate Xcode project if xcodegen is available, otherwise use SPM
if command -v xcodegen &> /dev/null; then
    echo "Using xcodegen..."
    xcodegen generate
else
    echo "xcodegen not found. Creating project structure manually..."

    # Create basic project directories
    mkdir -p Blitztext.xcodeproj/project.xcworkspace
    mkdir -p Blitztext.xcodeproj/xcshareddata/xcschemes
fi

echo ""
echo "Setup complete! Open Blitztext.xcodeproj in Xcode."
echo ""
echo "Next steps:"
echo "1. Open Blitztext.xcodeproj"
echo "2. Select your development team in Signing & Capabilities"
echo "3. Add your OpenAI API key in the app Settings"
echo "4. Build and run (Cmd+R)"
