#!/bin/bash

# Plex Media Drive Folder Structure Creation Script
# This script creates the recommended folder structure for Plex automation

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Script header
echo "=================================================="
echo "  Plex Media Server Folder Structure Creator"
echo "=================================================="
echo ""

# Check if drive letter is provided as argument
if [ $# -eq 0 ]; then
    print_error "Usage: $0 <drive_letter>"
    print_error "Example: $0 F"
    print_error "Example: $0 /mnt/plex-media"
    echo ""
    echo "For Windows: Use drive letter (F, G, H, etc.)"
    echo "For Linux: Use mount point path (/mnt/plex-media, /media/plex, etc.)"
    exit 1
fi

# Set the base path
DRIVE_INPUT="$1"

# Detect if we're on Windows (Git Bash/WSL) or Linux
if [[ "$DRIVE_INPUT" =~ ^[A-Za-z]$ ]]; then
    # Windows drive letter format
    BASE_PATH="/${DRIVE_INPUT,,}"  # Convert to lowercase for Git Bash
    DISPLAY_PATH="${DRIVE_INPUT^^}:\\"  # Uppercase for display
    PLATFORM="Windows"
elif [[ "$DRIVE_INPUT" =~ ^/.* ]]; then
    # Linux/Unix absolute path
    BASE_PATH="$DRIVE_INPUT"
    DISPLAY_PATH="$DRIVE_INPUT"
    PLATFORM="Linux"
else
    print_error "Invalid path format. Use drive letter (F) or absolute path (/mnt/plex-media)"
    exit 1
fi

print_header "Creating folder structure at: $DISPLAY_PATH"
print_status "Detected platform: $PLATFORM"
echo ""

# Check if base path exists/is accessible
if [ ! -d "$BASE_PATH" ] && [ "$PLATFORM" = "Linux" ]; then
    print_error "Base path $BASE_PATH does not exist or is not accessible"
    print_warning "Make sure the drive is mounted and you have write permissions"
    exit 1
fi

# Define the folder structure
declare -a FOLDERS=(
    "Media"
    "Media/Movies"
    "Media/TV Shows"
    "Media/Music"
    "Media/Anime"
    "Media/Documentaries"
    "Media/Other"
    "Downloads"
    "Downloads/Complete"
    "Downloads/Incomplete"
    "Downloads/Watch"
    "Downloads/Movies"
    "Downloads/TV"
    "Downloads/Music"
    "Backups"
    "Backups/Configs"
    "Backups/Database"
    "Scripts"
    "Temp"
)

# Create folders
print_status "Creating folder structure..."
echo ""

CREATED_COUNT=0
SKIPPED_COUNT=0

for folder in "${FOLDERS[@]}"; do
    FULL_PATH="$BASE_PATH/$folder"
    
    if [ -d "$FULL_PATH" ]; then
        print_warning "Already exists: $folder"
        ((SKIPPED_COUNT++))
    else
        if mkdir -p "$FULL_PATH" 2>/dev/null; then
            print_status "Created: $folder"
            ((CREATED_COUNT++))
        else
            print_error "Failed to create: $folder"
            echo "  Check permissions and try running as administrator/sudo"
        fi
    fi
done

echo ""
echo "=================================================="
print_header "Folder Structure Creation Complete"
echo "=================================================="
echo ""
print_status "Created: $CREATED_COUNT folders"
print_status "Skipped: $SKIPPED_COUNT folders (already existed)"
echo ""

# Display the created structure
print_header "Your Plex media folder structure:"
echo ""
echo "$DISPLAY_PATH"
echo "├── Media/"
echo "│   ├── Movies/"
echo "│   ├── TV Shows/"
echo "│   ├── Music/"
echo "│   ├── Anime/"
echo "│   ├── Documentaries/"
echo "│   └── Other/"
echo "├── Downloads/"
echo "│   ├── Complete/"
echo "│   ├── Incomplete/"
echo "│   ├── Watch/"
echo "│   ├── Movies/"
echo "│   ├── TV/"
echo "│   └── Music/"
echo "├── Backups/"
echo "│   ├── Configs/"
echo "│   └── Database/"
echo "├── Scripts/"
echo "└── Temp/"
echo ""

# Provide next steps
print_header "Next Steps:"
echo ""
echo "1. Download and install Plex Media Server"
echo "2. Configure Plex libraries to point to:"
if [ "$PLATFORM" = "Windows" ]; then
    echo "   - Movies: ${DISPLAY_PATH}Media\\Movies"
    echo "   - TV Shows: ${DISPLAY_PATH}Media\\TV Shows"
    echo "   - Music: ${DISPLAY_PATH}Media\\Music"
else
    echo "   - Movies: $DISPLAY_PATH/Media/Movies"
    echo "   - TV Shows: $DISPLAY_PATH/Media/TV Shows"
    echo "   - Music: $DISPLAY_PATH/Media/Music"
fi
echo "3. Configure automation tools (Sonarr/Radarr) to use Downloads folder"
echo "4. Set up automatic moving from Downloads/Complete to Media folders"
echo ""

# Permissions note for Linux
if [ "$PLATFORM" = "Linux" ]; then
    print_warning "Linux users: You may need to adjust folder permissions:"
    echo "sudo chown -R \$USER:\$USER $BASE_PATH"
    echo "sudo chmod -R 755 $BASE_PATH"
    echo ""
fi

print_status "Folder structure setup complete! Ready for Plex installation."
echo ""