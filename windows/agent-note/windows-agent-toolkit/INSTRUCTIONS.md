# Windows Agent Desktop Toolkit

Read this file when the user asks you to view or capture the Windows screen, inspect or control a native Windows application, move or click the mouse, or send keyboard input outside the integrated browser.

This directory is self-contained. `desktop.ps1` locates the bundled `nircmdc.exe` beside itself, so the directory can be moved or restored elsewhere without editing the script.

## Setup

In PowerShell, set `$toolkit` to the directory the user gave you:

```powershell
$toolkit = 'C:\path\to\windows-agent-toolkit'
$desktop = Join-Path $toolkit 'desktop.ps1'
```

When this copy remains at its original location, use:

```powershell
$desktop = "$HOME\Documents\windows-agent-toolkit\desktop.ps1"
```

## Commands

```powershell
# Capture the full virtual screen.
& $desktop screenshot "$env:TEMP\copilot-desktop.png"

# Move the pointer without clicking.
& $desktop move -X 500 -Y 300

# Click absolute screen coordinates.
& $desktop click -X 500 -Y 300
& $desktop click -X 500 -Y 300 -Button right
& $desktop click -X 500 -Y 300 -Double

# Send a NirCmd key sequence to the focused window.
& $desktop keys 'ctrl+l'
& $desktop keys 'enter'
& $desktop keys 'alt+f4'

# Paste literal text into the focused control.
& $desktop text 'literal text'
```

Prefer a direct command-line operation whenever it can complete the task; use desktop screenshots, mouse clicks, and keyboard input only for UI-only work.

## Required Workflow

1. Capture a fresh screenshot.
2. Inspect the PNG with the VS Code `view_image` tool at native resolution.
3. Determine absolute pixel coordinates from that image.
4. Perform only one small input action.
5. Capture again and verify the visible result.

Prefer integrated browser tools when the target is a browser page because they are element-aware. Use this toolkit for the Windows desktop and native applications.

## Black Screenshot Rule

A minimized or backgrounded RDP window produces a totally black screenshot on this machine. If the screenshot is totally black:

1. Do not click or type.
2. Use the VS Code Copilot `vscode_askQuestions` user-choice tool to tell the user: "Please restore the RDP window and keep it open, then tell me when it is ready."
3. Wait for the user's confirmation.
4. Capture a fresh screenshot and verify that it is visible before continuing.

A controlled test on 2026-09-14 measured 0% black sampled pixels while RDP was visible and 100% black after the RDP window was minimized for 10 seconds.

## Safety and Limitations

- Coordinates are absolute virtual-screen pixels and change with resolution, scaling, display layout, window movement, or RDP reconnection.
- A locked, disconnected, switched, or secure desktop can also block capture. Ask the user to reconnect or unlock it, then retry.
- `text` temporarily uses the text clipboard and restores the prior text value, but it cannot preserve copied images or file-list clipboard formats.
- Never request or send passwords, tokens, or other secrets through model-visible commands.
- Confirm before destructive, purchase, security-sensitive, or irreversible actions.
- The bundled executable is the user's portable NirCmd 2.87 binary. It is not digitally signed. Expected SHA-256: `C3E28C6E201D5C0206D941BED96C1C6219397DA9B563771D856DA1B6CC390554`.
