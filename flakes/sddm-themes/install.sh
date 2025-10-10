#!/bin/bash

# SDDM Astronaut Theme Selector with YAD GUI
# A script to select and apply themes for SDDM using the sddm-astronaut-theme project.

# Define paths
# Use ORIGINAL_HOME if set (after elevation), otherwise use HOME
HYPRDDM_DIR="${ORIGINAL_HOME:-$HOME}/hyprddm"
THEMES_PATH="/usr/share/sddm/themes/sddm-astronaut-theme"
FONTS_PATH="/usr/share/fonts"
METADATA_FILE="$THEMES_PATH/metadata.desktop"
SDDM_CONF="/etc/sddm.conf"
VIRTUAL_KBD_CONF="/etc/sddm.conf.d/virtualkbd.conf"
TEMP_DIR="/tmp/sddm-previews-$USER"
SCRIPT_PATH="$HYPRDDM_DIR/install.sh"
YAD_OUTPUT="/tmp/yad_output.$USER.$$"  # Unique file path for YAD output
METADATA_PERMS_FILE="/tmp/metadata_perms.$USER.$$"  # Store original permissions
THEMES_PATH_PERMS_FILE="/tmp/themes_path_perms.$USER.$$"  # Store original permissions for THEMES_PATH

# Function to log messages without debug clutter
log() {
    echo "$1"
}

# Function to detect distribution
detect_distribution() {
    if [ -f /etc/arch-release ]; then
        DISTRO="arch"
    elif [ -f /etc/void-release ]; then
        DISTRO="void"
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
    elif [ -f /etc/opensuse-release ] || [ -f /etc/SuSE-release ]; then
        DISTRO="opensuse"
    else
        DISTRO="unknown"
    fi
    log "Detected distribution: $DISTRO"
}

# Function to install dependencies
install_dependencies() {
    log "Installing required dependencies..."
    case $DISTRO in
        arch)
            pkexec pacman -S --noconfirm --needed sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg yad polkit xorg-xwayland imagemagick curl git xorg-server-xephyr
            ;;
        void)
            pkexec xbps-install -Sy sddm qt6-svg qt6-virtualkeyboard qt6-multimedia yad polkit xwayland imagemagick curl git xorg-server-xephyr
            ;;
        fedora)
            pkexec dnf install -y sddm qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia yad polkit xorg-x11-server-Xwayland imagemagick curl git xorg-x11-server-Xephyr
            ;;
        opensuse)
            pkexec zypper install -y sddm-qt6 libQt6Svg6 qt6-virtualkeyboard qt6-virtualkeyboard-imports qt6-multimedia yad polkit xorg-x11-server imagemagick curl git xorg-x11-server-xephyr
            ;;
        *)
            log "Unsupported distribution. Please install dependencies manually."
            log "Required packages: sddm, qt6-svg, qt6-virtualkeyboard, qt6-multimedia, yad, polkit, xwayland, imagemagick, curl, git, xorg-server-xephyr"
            ;;
    esac
}

# Function to check and install theme files
check_and_install_theme() {
    log "Installing SDDM Astronaut Theme with elevated privileges..."
    pkexec bash -c "
        # Ensure the parent directory exists
        log() { echo \"\$1\"; }
        log \"Ensuring parent directory /usr/share/sddm/themes exists...\"
        mkdir -p /usr/share/sddm/themes
        if [ \$? -ne 0 ]; then
            log \"Error: Failed to create /usr/share/sddm/themes directory.\"
            exit 1
        fi

        # Check if the themes directory exists and contains files
        if [ -d \"$THEMES_PATH\" ] && [ -n \"\$(ls -A \"$THEMES_PATH\")\" ]; then
            log \"Warning: $THEMES_PATH already exists. Removing it to ensure a clean installation...\"
            rm -rf \"$THEMES_PATH\"
            if [ \$? -ne 0 ]; then
                log \"Error: Failed to remove $THEMES_PATH. Please check permissions and try again.\"
                exit 1
            fi
            log \"Successfully removed $THEMES_PATH.\"
        fi

        # Explicitly create the target directory
        log \"Creating target directory $THEMES_PATH...\"
        mkdir -p \"$THEMES_PATH\"
        if [ \$? -ne 0 ]; then
            log \"Error: Failed to create $THEMES_PATH directory.\"
            exit 1
        fi

        # Proceed with installation
        log \"Installing SDDM Astronaut Theme from local repository...\"
        log \"Copying repository contents from $HYPRDDM_DIR to $THEMES_PATH...\"
        cp -r \"$HYPRDDM_DIR/\"* \"$THEMES_PATH/\"
        
        if [ \$? -ne 0 ]; then
            log \"Error: Failed to copy repository contents to $THEMES_PATH.\"
            exit 1
        fi
        
        if [ -d \"$THEMES_PATH/Fonts\" ]; then
            log \"Copying fonts from $THEMES_PATH/Fonts to $FONTS_PATH...\"
            mkdir -p \"$FONTS_PATH\"
            cp -r \"$THEMES_PATH/Fonts/\"* \"$FONTS_PATH/\"
            log \"Updating font cache...\"
            fc-cache -f
        fi
        
        log \"Configuring SDDM theme...\"
        echo \"[Theme]
Current=sddm-astronaut-theme\" | tee \"$SDDM_CONF\"
        
        log \"Enabling virtual keyboard...\"
        mkdir -p /etc/sddm.conf.d/
        echo \"[General]
InputMethod=qtvirtualkeyboard\" | tee \"$VIRTUAL_KBD_CONF\"
        
        log \"SDDM Astronaut Theme installed successfully.\"

        # Store original permissions and ownership of THEMES_PATH
        log \"Storing original permissions of $THEMES_PATH...\"
        stat -c '%a %U:%G' \"$THEMES_PATH\" > \"$THEMES_PATH_PERMS_FILE\"
        if [ \$? -ne 0 ]; then
            log \"Error: Failed to store original permissions of $THEMES_PATH.\"
            exit 1
        fi

        # Store original permissions and ownership of metadata.desktop
        log \"Storing original permissions of $METADATA_FILE...\"
        stat -c '%a %U:%G' \"$METADATA_FILE\" > \"$METADATA_PERMS_FILE\"
        if [ \$? -ne 0 ]; then
            log \"Error: Failed to store original permissions of $METADATA_FILE.\"
            exit 1
        fi

        # Make THEMES_PATH writable by the user
        log \"Making $THEMES_PATH writable by user $ORIGINAL_USER...\"
        chown \"$ORIGINAL_USER\" \"$THEMES_PATH\"
        chmod u+w \"$THEMES_PATH\"
        if [ \$? -ne 0 ]; then
            log \"Error: Failed to make $THEMES_PATH writable by $ORIGINAL_USER.\"
            exit 1
        fi

        # Make metadata.desktop writable by the user
        log \"Making $METADATA_FILE writable by user $ORIGINAL_USER...\"
        chown \"$ORIGINAL_USER\" \"$METADATA_FILE\"
        chmod u+w \"$METADATA_FILE\"
        if [ \$? -ne 0 ]; then
            log \"Error: Failed to make $METADATA_FILE writable by $ORIGINAL_USER.\"
            exit 1
        fi
    "
    if [ $? -ne 0 ]; then
        log "Error: Failed to install SDDM Astronaut Theme."
        exit 1
    fi
}

# Function to handle self-elevation for installation steps
self_elevate_install() {
    if [ "$(id -u)" -ne 0 ]; then
        log "Elevating privileges for installation..."

        export ORIGINAL_USER=$(whoami)
        export ORIGINAL_UID=$(id -u)
        export ORIGINAL_HOME="$HOME"
        export ORIGINAL_HYPRDDM_DIR="$HYPRDDM_DIR"
        
        log "Executing pkexec to elevate privileges for installation..."
        pkexec env ORIGINAL_USER="$ORIGINAL_USER" \
            ORIGINAL_UID="$ORIGINAL_UID" \
            ORIGINAL_HOME="$ORIGINAL_HOME" \
            ORIGINAL_HYPRDDM_DIR="$ORIGINAL_HYPRDDM_DIR" \
            "$SCRIPT_PATH" --install-only
        if [ $? -ne 0 ]; then
            log "Error: Failed to elevate privileges for installation."
            exit 1
        fi
    fi
    
    if [ -n "$ORIGINAL_USER" ] && [ "$ORIGINAL_USER" != "root" ]; then
        export HYPRDDM_DIR="$ORIGINAL_HYPRDDM_DIR"
    fi

    # Debug: Check permissions after installation
    log "Checking permissions after installation..."
    log "Permissions of $THEMES_PATH: $(ls -ld "$THEMES_PATH")"
    log "Permissions of $METADATA_FILE: $(ls -l "$METADATA_FILE")"
}

# Function to clean up temporary files and restore permissions
cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    rm -f "$YAD_OUTPUT"

    # Restore original permissions of metadata.desktop
    if [ -f "$METADATA_PERMS_FILE" ]; then
        log "Restoring original permissions of $METADATA_FILE..."
        read perms owner_group < "$METADATA_PERMS_FILE"
        pkexec chmod "$perms" "$METADATA_FILE"
        pkexec chown "$owner_group" "$METADATA_FILE"
        if [ $? -eq 0 ]; then
            log "Successfully restored permissions of $METADATA_FILE."
        else
            log "Warning: Failed to restore original permissions of $METADATA_FILE."
        fi
        rm -f "$METADATA_PERMS_FILE"
    fi

    # Restore original permissions of THEMES_PATH
    if [ -f "$THEMES_PATH_PERMS_FILE" ]; then
        log "Restoring original permissions of $THEMES_PATH..."
        read perms owner_group < "$THEMES_PATH_PERMS_FILE"
        pkexec chmod "$perms" "$THEMES_PATH"
        pkexec chown "$owner_group" "$THEMES_PATH"
        if [ $? -eq 0 ]; then
            log "Successfully restored permissions of $THEMES_PATH."
        else
            log "Warning: Failed to restore original permissions of $THEMES_PATH."
        fi
        rm -f "$THEMES_PATH_PERMS_FILE"
    fi
}

# Function to prepare thumbnails
prepare_thumbnails() {
    log "Preparing thumbnails..."
    mkdir -p "$TEMP_DIR"
    chmod -R 755 "$TEMP_DIR"
    
    declare -A theme_previews
    theme_previews=(
        ["chainsaw_fury"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/chainsaw_fury.png"
        ["cloud"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/cloud.png"
        ["neon_jinx"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/neon_jinx.png"
        ["savage"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/savage.png"
        ["starman"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/starman.png"
        ["astronaut"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/astronaut.png"
        ["cyberpunk"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/cyberpunk.png"
        ["hyprland_kath"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/hyprland_kath.png"
        ["jake_the_dog"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/jake_the_dog.png"
        ["japanese_aesthetic"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/japanese_aesthetic.png"
        ["pixel_sakura"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/pixel_sakura_static.png"
        ["post-apocalyptic_hacker"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/post-apocalyptic_hacker.png"
        ["purple_leaves"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/purple_leaves.png"
        ["renzu"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/renzu.png"
        ["cybermonk"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/cybermonk.png"
        ["ghost"]="https://github.com/nomadxxxx/hyprddm/raw/master/Previews/ghost.png"
    )
    
    for theme in "${!theme_previews[@]}"; do
        local_file="$THEMES_PATH/Backgrounds/$theme.png"
        preview_file="$TEMP_DIR/$theme-preview.png"
        if [ -f "$local_file" ]; then
            log "Generating thumbnail for $theme from local file $local_file..."
            magick "$local_file" -resize 200x150 "$preview_file" 2>/dev/null
            if [ $? -ne 0 ]; then
                log "Warning: Failed to generate thumbnail for $theme from $local_file."
            fi
        elif [ ! -f "$preview_file" ]; then
            url="${theme_previews[$theme]}"
            log "Downloading preview for $theme from $url..."
            curl -s -L --progress-bar "$url" -o "$preview_file"
            if [ $? -ne 0 ]; then
                log "Warning: Failed to download preview for $theme from $url."
            else
                log "Generating thumbnail for $theme..."
                magick "$preview_file" -resize 200x150 "$preview_file" 2>/dev/null
                if [ $? -ne 0 ]; then
                    log "Warning: Failed to generate thumbnail for $theme from $preview_file. Image may be corrupted."
                    rm -f "$preview_file"  # Remove the corrupted file
                fi
            fi
        fi
    done
}
# Function to apply selected theme
apply_theme() {
    local theme="$1"
    log "Applying theme: $theme"
    # Since $METADATA_FILE is now writable by the user, we can modify it directly
    sed -i "s/ConfigFile=.*/ConfigFile=Themes\/$theme.conf/" "$METADATA_FILE"
    if [ $? -ne 0 ]; then
        log "Error: Failed to apply theme $theme to $METADATA_FILE."
        return 1
    fi
    # Writing to $SDDM_CONF still requires pkexec
    echo "[Theme]
Current=sddm-astronaut-theme" | pkexec tee "$SDDM_CONF" > /dev/null
    if [ $? -ne 0 ]; then
        log "Error: Failed to update $SDDM_CONF."
        return 1
    fi
    log "Theme applied successfully."
}

# Function to test theme
test_theme() {
    local theme="$1"
    log "Testing theme: $theme"

    # Since $METADATA_FILE and its parent directory are now writable by the user, we can modify it directly
    # Back up the metadata.desktop file
    log "Backing up $METADATA_FILE to $METADATA_FILE.bak..."
    cp "$METADATA_FILE" "$METADATA_FILE.bak"
    if [ $? -ne 0 ]; then
        log "Error: Failed to back up $METADATA_FILE."
        return 1
    fi

    # Set the theme for testing
    log "Setting theme $theme in $METADATA_FILE..."
    sed -i "s/ConfigFile=.*/ConfigFile=Themes\/$theme.conf/" "$METADATA_FILE"
    if [ $? -ne 0 ]; then
        log "Error: Failed to modify $METADATA_FILE for testing."
        mv "$METADATA_FILE.bak" "$METADATA_FILE" 2>/dev/null
        return 1
    fi

    # Detect session type
    log "Detecting session type..."
    if [ -n "$WAYLAND_DISPLAY" ]; then
        SESSION_TYPE="Wayland"
    elif [ -n "$DISPLAY" ]; then
        SESSION_TYPE="X11"
    else
        SESSION_TYPE="TTY"
    fi
    log "Session type: $SESSION_TYPE"

    # Check if a display server is running
    log "Checking for display server..."
    USE_NESTED_SERVER=0
    if [ -z "$DISPLAY" ]; then
        log "Warning: DISPLAY variable is not set. No X server or Wayland session detected."
        USE_NESTED_SERVER=1
    else
        log "DISPLAY=$DISPLAY"
        log "XAUTHORITY=${XAUTHORITY:-$HOME/.Xauthority}"
    fi

    # Check if XWayland is installed (for Wayland sessions)
    if [ "$SESSION_TYPE" = "Wayland" ] && ! command -v Xwayland >/dev/null 2>&1; then
        log "Warning: Running in a Wayland session, but XWayland is not installed."
        yad --title="Test Failed" \
            --text="Failed to test theme '$theme'. XWayland is required for Wayland sessions.\nPlease install XWayland (e.g., 'sudo pacman -S xorg-xwayland' on Arch)." \
            --button="OK:0" \
            --width=400 \
            --height=150 \
            --center
        mv "$METADATA_FILE.bak" "$METADATA_FILE" 2>/dev/null
        return 1
    fi

    # Set Qt environment variables for Wayland
    if [ "$SESSION_TYPE" = "Wayland" ]; then
        export QT_LOGGING_RULES="qt5ct.debug=false"
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export QT_QPA_PLATFORM="wayland;xcb"  # Fallback to XCB if Wayland fails
    fi

    # Run the test
    log "Running SDDM greeter test as user $(whoami)..."
    TEST_RET=1
    GREETER_OUTPUT=""
    if [ "$USE_NESTED_SERVER" -eq 1 ]; then
        # Fallback to a nested X server using Xephyr
        if command -v Xephyr >/dev/null 2>&1; then
            log "Starting a nested X server with Xephyr..."
            Xephyr :99 -ac -screen 800x600 -host-cursor &
            XEPHYR_PID=$!
            sleep 2  # Wait for Xephyr to start
            GREETER_OUTPUT=$(env DISPLAY=:99 \
                QT_LOGGING_RULES="qt5ct.debug=false" \
                sddm-greeter-qt6 --test-mode --theme "$THEMES_PATH" 2>&1)
            TEST_RET=$?
            kill $XEPHYR_PID 2>/dev/null
        else
            log "Error: Xephyr is not installed. Cannot start a nested X server."
            yad --title="Test Failed" \
                --text="Failed to test theme '$theme'. No display server detected, and Xephyr is not installed.\nPlease run this script in a graphical session (X11 or Wayland with XWayland).\nIf using SSH, enable X forwarding with 'ssh -X'." \
                --button="OK:0" \
                --width=400 \
                --height=150 \
                --center
            mv "$METADATA_FILE.bak" "$METADATA_FILE" 2>/dev/null
            return 1
        fi
    else
        # Run directly as the current user
        GREETER_OUTPUT=$(env DISPLAY="$DISPLAY" \
            XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}" \
            QT_LOGGING_RULES="qt5ct.debug=false" \
            QT_QPA_PLATFORM="wayland;xcb" \
            sddm-greeter-qt6 --test-mode --theme "$THEMES_PATH" 2>&1)
        TEST_RET=$?
    fi

    # Log the greeter output for debugging
    log "SDDM greeter output:"
    log "$GREETER_OUTPUT"

    # Restore the original metadata.desktop file
    log "Restoring original $METADATA_FILE..."
    mv "$METADATA_FILE.bak" "$METADATA_FILE"
    if [ $? -ne 0 ]; then
        log "Error: Failed to restore $METADATA_FILE."
        return 1
    fi

    # Check the result of the test
    if [ $TEST_RET -ne 0 ]; then
        log "Warning: SDDM greeter test failed. This may be due to missing dependencies or X server issues."
        log "DISPLAY=$DISPLAY, XAUTHORITY=$XAUTHORITY"
        ERROR_MESSAGE="Failed to test theme '$theme'.\n"
        if [ "$SESSION_TYPE" = "TTY" ]; then
            ERROR_MESSAGE="$ERROR_MESSAGE\nRunning in a TTY. Please start an X server (e.g., 'startx') or run this script in a graphical session."
        elif [ "$SESSION_TYPE" = "Wayland" ]; then
            ERROR_MESSAGE="$ERROR_MESSAGE\nRunning in a Wayland session. Ensure XWayland is running (check 'ps aux | grep Xwayland')."
        else
            ERROR_MESSAGE="$ERROR_MESSAGE\nEnsure an X server or Wayland with XWayland is running.\nDISPLAY=$DISPLAY\nXAUTHORITY=$XAUTHORITY"
        fi
        ERROR_MESSAGE="$ERROR_MESSAGE\n\nGreeter output:\n$GREETER_OUTPUT"
        yad --title="Test Failed" \
            --text="$ERROR_MESSAGE" \
            --button="OK:0" \
            --width=600 \
            --height=300 \
            --center
    else
        log "Test completed successfully."
    fi
}

# Function to download the repository
download_repository() {
    log "Checking for existing hyprddm directory in ${ORIGINAL_HOME:-$HOME}..."
    if [ -d "$HYPRDDM_DIR" ]; then
        log "Directory $HYPRDDM_DIR already exists. Removing it with elevated privileges to ensure a clean download..."
        pkexec rm -rf "$HYPRDDM_DIR"
        if [ $? -ne 0 ]; then
            log "Error: Failed to remove $HYPRDDM_DIR. Please check permissions and try again."
            exit 1
        fi
        log "Successfully removed $HYPRDDM_DIR."
    fi

    log "Creating hyprddm directory in ${ORIGINAL_HOME:-$HOME}..."
    mkdir -p "$HYPRDDM_DIR"
    if [ $? -ne 0 ]; then
        log "Error: Failed to create $HYPRDDM_DIR directory."
        exit 1
    fi

    log "Cloning repository from https://github.com/nomadxxxx/hyprddm.git to $HYPRDDM_DIR..."
    git clone -b master --depth 1 --progress https://github.com/nomadxxxx/hyprddm.git "$HYPRDDM_DIR" 2>&1
    
    if [ $? -ne 0 ]; then
        log "Error: Failed to clone the repository. Please check your internet connection and try again."
        exit 1
    fi

    log "Setting execute permissions on $SCRIPT_PATH..."
    chmod +x "$SCRIPT_PATH"
}

# Function to perform installation steps (run as root)
install_only() {
    # Unset the EXIT trap to prevent cleanup from running in this subprocess
    trap - EXIT

    log "Performing installation steps as root..."
    detect_distribution
    install_dependencies
    check_and_install_theme
    log "Installation steps completed."
}

# Main function
main() {
    log "Starting main function..."
    
    # Perform installation steps with elevation
    self_elevate_install
    
    log "Proceeding with GUI as original user..."
    
    # Prepare thumbnails
    prepare_thumbnails
    
    # List of available themes (new themes at the top, removed black_hole)
    THEMES=(
        "renzu"
        "cybermonk"
        "ghost"
        "chainsaw_fury"
        "cloud"
        "neon_jinx"
        "savage"
        "starman"
        "astronaut"
        "cyberpunk"
        "hyprland_kath"
        "jake_the_dog"
        "japanese_aesthetic"
        "pixel_sakura"
        "post-apocalyptic_hacker"
        "purple_leaves"
    )
    
    # Build YAD list with previews
    yad_args=()
    yad_args+=("--title" "SDDM Astronaut Theme Selector")
    yad_args+=("--width" "800")
    yad_args+=("--height" "600")
    yad_args+=("--center")
    yad_args+=("--text" "Select an SDDM Theme")
    yad_args+=("--list")
    yad_args+=("--column" "Preview:IMG")
    yad_args+=("--column" "Theme:TEXT")
    yad_args+=("--column" "Description:TEXT")
    
    # Add each theme as a row
    for theme in "${THEMES[@]}"; do
        preview_file="$TEMP_DIR/$theme-preview.png"
        if [ -f "$preview_file" ]; then
            yad_args+=("$preview_file")
            yad_args+=("$theme")
            yad_args+=("SDDM $theme theme")
        else
            yad_args+=("/usr/share/icons/hicolor/48x48/apps/sddm.png")
            yad_args+=("$theme")
            yad_args+=("SDDM $theme theme - preview unavailable")
        fi
    done
    
    yad_args+=("--button=Apply:0")
    yad_args+=("--button=Test:2")
    yad_args+=("--button=Cancel:1")
    
    # Launch YAD GUI and capture output
    log "Launching theme selector GUI..."
    yad "${yad_args[@]}" --print-column=2 > "$YAD_OUTPUT" 2>&1
    RET=$?
    SELECTION=$(cat "$YAD_OUTPUT" | grep -v "gtk-" | tr -d '|' | head -n 1)
    
    case $RET in
        0)  # Apply
            if [ -n "$SELECTION" ]; then
                apply_theme "$SELECTION"
                yad --title="Success" \
                    --text="Theme '$SELECTION' applied successfully!" \
                    --button="OK:0" \
                    --width=300 \
                    --height=100 \
                    --center
            else
                log "Error: No theme selected for Apply."
            fi
            ;;
        2)  # Test
            if [ -n "$SELECTION" ]; then
                test_theme "$SELECTION"
            else
                log "Error: No theme selected for Test."
            fi
            ;;
        1|252)  # Cancel or closed
            log "Operation cancelled."
            ;;
        *)  # Unexpected exit code
            log "Error: Unexpected exit code $RET from YAD."
            ;;
    esac
}

# Execute script
log "Starting script execution..."

# Register cleanup function to run on exit of the main script
trap cleanup EXIT

# Check if we're running in install-only mode
if [ "$1" = "--install-only" ]; then
    install_only
    exit 0
fi

# Check if the repository already exists in HYPRDDM_DIR
if [ ! -d "$HYPRDDM_DIR" ] || [ ! -f "$SCRIPT_PATH" ]; then
    log "Repository not found in $HYPRDDM_DIR. Downloading repository..."
    download_repository
    log "Repository downloaded. Executing script from $HYPRDDM_DIR..."
    cd "$HYPRDDM_DIR"
    exec "$SCRIPT_PATH"
else
    log "Repository already exists in $HYPRDDM_DIR. Proceeding with installation..."
    cd "$HYPRDDM_DIR"
    main
fi