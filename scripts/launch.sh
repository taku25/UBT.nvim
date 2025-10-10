#!/bin/bash
# launch.sh – Cross-platform UBT launcher via dotnet (Simplified Pass-through version)

# Exit immediately if a command exits with a non-zero status.
set -e

# --- 1. Get Engine Path ---
# The first argument is always the absolute path to the Unreal Engine root.
ENGINE_PATH="$1"
if [[ -z "$ENGINE_PATH" ]]; then
    echo "[launch.sh] ERROR: Missing Engine Path argument." >&2
    exit 1
fi

# Remove the first argument (Engine Path) from the list of arguments.
shift

# --- 2. Validate UBT DLL ---
UBT_DLL="${ENGINE_PATH}/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.dll"
if [[ ! -f "$UBT_DLL" ]]; then
    echo "[launch.sh] ERROR: UnrealBuildTool.dll not found at: '$UBT_DLL'" >&2
    exit 1
fi

# --- 3. Run dotnet with all remaining arguments ---
# "$@" passes all remaining arguments exactly as they were received from Lua,
# correctly handling spaces and special characters.
dotnet "$UBT_DLL" "$@"

# Exit with the exit code of the dotnet command.
exit $?
