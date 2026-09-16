#!/bin/bash

# ==============================================================================
# ComfyUI GUI Installer for Arch Linux (Fish Shell Edition)
# ==============================================================================

# 1. Dependency Check
if grep -q avx /proc/cpuinfo; then
    echo "AVX supported"
    NEEDS_KORNIA_FIX=false
else
    echo "No AVX detected - kornia workaround will be applied automatically after install"
    NEEDS_KORNIA_FIX=true
fi

MISSING_PKGS=""
for pkg in zenity git python; do 2>/dev/null
    if ! command -v "$pkg" &> /dev/null; then
        MISSING_PKGS="$MISSING_PKGS $pkg"
    fi
done

if [ -n "$MISSING_PKGS" ]; then
    echo "Missing dependencies detected:$MISSING_PKGS"
    echo "Requesting sudo privileges to install them via pacman..."
    sudo pacman -S --noconfirm $MISSING_PKGS || {
        echo "Failed to install dependencies. Exiting."
        exit 1
    }
fi

# 2. Welcome & Directory Selection
zenity --info --title="ComfyUI Installer" --text="Welcome to the ComfyUI Installer.\n\nClick OK to select your installation directory." --width=400 2>/dev/null
INSTALL_DIR=$(zenity --file-selection --directory --title="Choose Installation Directory" --filename="$HOME/") 2>/dev/null
if [ -z "$INSTALL_DIR" ]; then exit 0; fi

# 3. GPU Configuration
GPU_TYPE=$(zenity --list --title="Select GPU Type" --text="Which GPU do you have?" \ 2>/dev/null
    --radiolist --column="Select" --column="GPU" \
    TRUE "NVIDIA" \
    FALSE "AMD" \
    FALSE "CPU Only" \
    --width=400 --height=250)
if [ -z "$GPU_TYPE" ]; then exit 0; fi

LOG_FILE="/tmp/comfyui_install.log"
> "$LOG_FILE"

# 4. Installation Process
(
    echo "10"
    echo "# Cloning ComfyUI repository..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "$INSTALL_DIR/ComfyUI" >> "$LOG_FILE" 2>&1 || exit 1

    echo "30"
    echo "# Creating Python virtual environment..."
    cd "$INSTALL_DIR/ComfyUI" || exit 1

    # Use python3.12 if available (to fix Arch PyTorch 2.8.0 issues), otherwise use default python
    if command -v python3.12 &> /dev/null; then
        python3.12 -m venv venv >> "$LOG_FILE" 2>&1 || exit 1
    else
        python -m venv venv >> "$LOG_FILE" 2>&1 || exit 1
    fi

    echo "40"
    echo "# Activating virtual environment..."
    source venv/bin/activate || exit 1

    echo "50"
    echo "# Installing PyTorch for $GPU_TYPE (This will take a while)..."
    if [ "$GPU_TYPE" == "NVIDIA" ]; then
        pip install torch torchvision torchaudio >> "$LOG_FILE" 2>&1 || exit 1
    elif [ "$GPU_TYPE" == "AMD" ]; then
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.1 >> "$LOG_FILE" 2>&1 || exit 1
    else
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu >> "$LOG_FILE" 2>&1 || exit 1
    fi

    echo "80"
    echo "# Installing ComfyUI dependencies..."
    pip install -r requirements.txt >> "$LOG_FILE" 2>&1 || exit 1

    if [ "$NEEDS_KORNIA_FIX" = true ]; then
        echo "90"
        echo "# No AVX detected - removing kornia (workaround)..."
        pip uninstall -y kornia kornia_rs >> "$LOG_FILE" 2>&1
    fi

    echo "95"
    echo "# Creating Fish launch script..."
    LAUNCH_SCRIPT="$INSTALL_DIR/ComfyUI/run_comfyui.fish"
