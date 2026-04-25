#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Auto-install libtmux if not available
LIBTMUX_AVAILABLE=$(python3 -c "import importlib.util; print(importlib.util.find_spec('libtmux') is not None)" 2>/dev/null)
if [ "$LIBTMUX_AVAILABLE" != "True" ]; then
    tmux display "Installing libtmux dependency..."

    # Try multiple installation methods in order of preference
    installed=false

    # Method 1: uv (fastest, handles externally-managed envs automatically)
    if command -v uv &> /dev/null; then
        uv pip install libtmux 2>/dev/null && installed=true
    fi

    # Method 2: pipx (isolated environment, good for CLI tools)
    if [ "$installed" = false ] && command -v pipx &> /dev/null; then
        pipx install libtmux 2>/dev/null && installed=true
    fi

    # Method 3: pip with --break-system-packages (for externally-managed envs like Homebrew Python)
    if [ "$installed" = false ]; then
        python3 -m pip install --break-system-packages libtmux 2>/dev/null && installed=true
    fi

    # Method 4: pip --user (legacy, may work on some systems)
    if [ "$installed" = false ]; then
        python3 -m pip install --user libtmux 2>/dev/null && installed=true
    fi

    # Verify installation
    LIBTMUX_AVAILABLE=$(python3 -c "import importlib.util; print(importlib.util.find_spec('libtmux') is not None)" 2>/dev/null)
    if [ "$LIBTMUX_AVAILABLE" != "True" ]; then
        tmux display "ERROR: tmux-window-name - Failed to install libtmux. Try: uv pip install libtmux OR pip3 install --break-system-packages libtmux"
        exit 0
    fi
    tmux display "libtmux installed successfully!"
fi

# Set PYTHONPATH to include the package directory for TPM/manual installs
export PYTHONPATH="$CURRENT_DIR:$PYTHONPATH"

tmux set -g automatic-rename on # Set automatic-rename on to make #{automatic-rename} be on when a new window is been open without a name
tmux set-hook -g 'after-new-window[8921]' 'set -wF @tmux_window_name_enabled \#\{automatic-rename\} ; set -w automatic-rename off'
tmux set-hook -g 'after-select-window[8921]' "run-shell -b \"PYTHONPATH='$CURRENT_DIR' python3 -m tmux_window_name.cli\""

############################################################################################
### Hacks for preserving users custom window names, read more at enable_user_rename_hook ###
############################################################################################

PYTHONPATH="$CURRENT_DIR" python3 -m tmux_window_name.cli --enable_rename_hook

# Disabling rename hooks when tmux-ressurect restores the sessions
tmux set -g @resurrect-hook-pre-restore-all "PYTHONPATH='$CURRENT_DIR' python3 -m tmux_window_name.cli --disable_rename_hook"
tmux set -g @resurrect-hook-post-restore-all "PYTHONPATH='$CURRENT_DIR' python3 -m tmux_window_name.cli --post_restore"