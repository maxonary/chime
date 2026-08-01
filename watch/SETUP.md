# Setting Up Haptic watchOS Project in Xcode

Since Swift Package Manager creates executables (not .app bundles), we need a proper Xcode project.

## Quick Setup

1. **Open Xcode**
2. **File** → **New** → **Project**
3. Select **watchOS** → **App**
4. Configure:
   - **Product Name**: `Haptic`
   - **Team**: Your Apple team
   - **Organization**: Your name/company
   - Uncheck "Include Tests"
5. **Create**

## Then Replace the Files

Once the project is created in Xcode:

1. Delete these default files in Xcode:
   - `ContentView.swift`
   - `HapticApp.swift` (the default one)

2. Copy our Swift files from `Haptic/` directory:
   - `HapticApp.swift` → Root
   - `Models/` → Copy folder
   - `Managers/` → Copy folder
   - `Views/` → Copy folder

3. Make sure all files are added to the **Haptic** target

## Build & Run

- Select **Haptic** scheme (top left)
- Select **Apple Watch** device/simulator
- Press **Cmd+R** to build and run

---

**Note**: The files are already here in the `Haptic/` folder. Just create the empty Xcode project and drag our files in.
