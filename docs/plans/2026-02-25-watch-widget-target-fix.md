# Watch / Widget Target Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix Watch and Widget extension targets so the app installs and tests pass on iOS Simulator.

**Architecture:** Modernize Watch from legacy WatchKit 2 two-target (container + extension) to single-target modern watchOS app. Fix Widget to use generated Info.plist. Consolidate duplicated ActivityAttributes.

**Tech Stack:** Xcode project configuration (pbxproj), SwiftUI, WidgetKit, WatchConnectivity

**Design doc:** `docs/plans/2026-02-25-watch-widget-target-fix-design.md`

---

### Task 1: Delete KokukokuWatchExtension target from pbxproj

The Extension target is being merged into the Watch app target. Remove all Extension-specific objects but **keep** the source file references and build file entries (they'll be reused by the Watch target).

**Files:**
- Modify: `app/Kokukoku/Kokukoku.xcodeproj/project.pbxproj`

**Step 1: Remove Extension-only PBXBuildFile**

Delete this line (the appex embed reference):
```
E67BED7B8F10790F7AF6AAD1 /* KokukokuWatchExtension.appex in Embed Foundation Extensions */ = {isa = PBXBuildFile; fileRef = E4FC1E0D68D7A0D758597848 /* KokukokuWatchExtension.appex */; settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); }; };
```

**Step 2: Remove Extension PBXContainerItemProxy**

Delete this block (lines 29-35):
```
706C1EF6D855B92250D0496A /* PBXContainerItemProxy */ = {
    isa = PBXContainerItemProxy;
    containerPortal = C3EE8C992F4DDC6E00522F61 /* Project object */;
    proxyType = 1;
    remoteGlobalIDString = 5C4184041F27E9B02A1BA4B6;
    remoteInfo = KokukokuWatchExtension;
};
```

**Step 3: Remove "Embed Foundation Extensions" PBXCopyFilesBuildPhase**

Delete this block (lines 75-85):
```
E858BB2B8B4EB46D41D7F083 /* Embed Foundation Extensions */ = {
    isa = PBXCopyFilesBuildPhase;
    buildActionMask = 2147483647;
    dstPath = "";
    dstSubfolderSpec = 13;
    files = (
        E67BED7B8F10790F7AF6AAD1 /* KokukokuWatchExtension.appex in Embed Foundation Extensions */,
    );
    name = "Embed Foundation Extensions";
    runOnlyForDeploymentPostprocessing = 0;
};
```

**Step 4: Remove Extension PBXFileReference (product)**

Delete this line:
```
E4FC1E0D68D7A0D758597848 /* KokukokuWatchExtension.appex */ = {isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = KokukokuWatchExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; };
```

**Step 5: Remove Extension product from Products group**

In the Products group (`C3EE8CA22F4DDC6E00522F61`), remove:
```
E4FC1E0D68D7A0D758597848 /* KokukokuWatchExtension.appex */,
```

**Step 6: Remove Extension PBXNativeTarget**

Delete the entire block (lines 235-251):
```
5C4184041F27E9B02A1BA4B6 /* KokukokuWatchExtension */ = {
    isa = PBXNativeTarget;
    ...
};
```

**Step 7: Remove Extension PBXTargetDependency**

Delete (lines 477-481):
```
7ABD7D74A887BC05E7FF264D /* PBXTargetDependency */ = {
    isa = PBXTargetDependency;
    target = 5C4184041F27E9B02A1BA4B6 /* KokukokuWatchExtension */;
    targetProxy = 706C1EF6D855B92250D0496A /* PBXContainerItemProxy */;
};
```

**Step 8: Remove Extension build phases (Frameworks + Resources)**

Delete:
```
E5EEDC110A4FDD8F3DFA211E /* Frameworks */ = {
    isa = PBXFrameworksBuildPhase;
    ...
};
```
and:
```
28FC332A50D0FA349943DF73 /* Resources */ = {
    isa = PBXResourcesBuildPhase;
    ...
};
```

**Step 9: Remove Extension XCBuildConfigurations and XCConfigurationList**

Delete both configs (`D6E075A6F812005EC9F486A4` Debug, `B01049803F7A4A5F37099660` Release) and the list:
```
0404603CCBF522F4B68BCBB5 /* Build configuration list for PBXNativeTarget "KokukokuWatchExtension" */ = {
    ...
};
```

**Step 10: Remove Extension from project target list and attributes**

In PBXProject targets array, remove:
```
5C4184041F27E9B02A1BA4B6 /* KokukokuWatchExtension */,
```

In TargetAttributes, remove:
```
5C4184041F27E9B02A1BA4B6 = {
    CreatedOnToolsVersion = 26.2;
};
```

**Step 11: Rename the group from KokukokuWatchExtension to KokukokuWatch**

Change group `41D001E5241EC69F634D3FCD`:
```
name = KokukokuWatchExtension;
```
to:
```
name = KokukokuWatch;
```

**Step 12: Verify build**

Run: `make build-macos`
Expected: Build Succeeded (macOS doesn't include Watch/Widget)

**Step 13: Commit**

```
git add app/Kokukoku/Kokukoku.xcodeproj/project.pbxproj
git commit -m "refactor: remove KokukokuWatchExtension target from project"
```

---

### Task 2: Modernize KokukokuWatch target

Convert the Watch container app to a standalone modern watchOS app.

**Files:**
- Modify: `app/Kokukoku/Kokukoku.xcodeproj/project.pbxproj`

**Step 1: Change product type**

In KokukokuWatch target (`3DAD69EFBDEBAA0257C5C10D`), change:
```
productType = "com.apple.product-type.application.watchapp2";
```
to:
```
productType = "com.apple.product-type.application";
```

**Step 2: Add Sources phase and remove Embed Foundation Extensions from buildPhases**

Change the Watch target's buildPhases from:
```
buildPhases = (
    804EEFB845015B27D64D5814 /* Frameworks */,
    20FFAEC9C133B24D92BA5E6E /* Resources */,
    E858BB2B8B4EB46D41D7F083 /* Embed Foundation Extensions */,
);
```
to (adding the Extension's former Sources phase, removing the deleted Embed phase):
```
buildPhases = (
    0AFB5B66D201CB59027589E4 /* Sources */,
    804EEFB845015B27D64D5814 /* Frameworks */,
    20FFAEC9C133B24D92BA5E6E /* Resources */,
);
```

**Step 3: Clear dependencies**

Change:
```
dependencies = (
    7ABD7D74A887BC05E7FF264D /* PBXTargetDependency */,
);
```
to:
```
dependencies = (
);
```

**Step 4: Update Watch Debug build settings**

In `4A7961EE63C38EB91AA57A48` (KokukokuWatch Debug), add `LD_RUNPATH_SEARCH_PATHS`:
```
LD_RUNPATH_SEARCH_PATHS = (
    "$(inherited)",
    "@executable_path/Frameworks",
);
```

**Step 5: Update Watch Release build settings**

In `EF466A0BAF890BEF872502C0` (KokukokuWatch Release), add `LD_RUNPATH_SEARCH_PATHS`:
```
LD_RUNPATH_SEARCH_PATHS = (
    "$(inherited)",
    "@executable_path/Frameworks",
);
```

**Step 6: Build for iOS Simulator**

Run: `build_sim` (XcodeBuildMCP)
Expected: Build Succeeded (Watch app compiles as standalone)

**Step 7: Commit**

```
git add app/Kokukoku/Kokukoku.xcodeproj/project.pbxproj
git commit -m "refactor: modernize KokukokuWatch to single-target watchOS app"
```

---

### Task 3: Fix Widget Info.plist generation

Switch Widget from manual Info.plist to Xcode auto-generation.

**Files:**
- Modify: `app/Kokukoku/Kokukoku.xcodeproj/project.pbxproj`
- Delete: `app/Kokukoku/KokukokuWidget/Info.plist`

**Step 1: Update Widget Debug build settings**

In `C9756A7BE23896E28AB16E1D` (KokukokuWidget Debug), make these changes:
- Change `GENERATE_INFOPLIST_FILE = NO` → `GENERATE_INFOPLIST_FILE = YES`
- Remove `INFOPLIST_FILE = KokukokuWidget/Info.plist`
- Add `INFOPLIST_KEY_CFBundleDisplayName = "Kokukoku Widget"`
- Add `INFOPLIST_KEY_NSExtensionPointIdentifier = "com.apple.widgetkit-extension"`

**Step 2: Update Widget Release build settings**

In `E5B3B6AF5A8B7A0BFDD5D48F` (KokukokuWidget Release), same changes:
- Change `GENERATE_INFOPLIST_FILE = NO` → `GENERATE_INFOPLIST_FILE = YES`
- Remove `INFOPLIST_FILE = KokukokuWidget/Info.plist`
- Add `INFOPLIST_KEY_CFBundleDisplayName = "Kokukoku Widget"`
- Add `INFOPLIST_KEY_NSExtensionPointIdentifier = "com.apple.widgetkit-extension"`

**Step 3: Remove Info.plist PBXFileReference**

Delete line:
```
91D29E068ED7A0C9D3FD12FA /* Info.plist */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = text.plist.xml; name = Info.plist; path = KokukokuWidget/Info.plist; sourceTree = "<group>"; };
```

And remove from KokukokuWidget group (`84A30BC9C4D4764D6BB91AFF`) children:
```
91D29E068ED7A0C9D3FD12FA /* Info.plist */,
```

**Step 4: Delete the manual Info.plist file**

```bash
rm app/Kokukoku/KokukokuWidget/Info.plist
```

**Step 5: Build for iOS Simulator**

Run: `build_sim` (XcodeBuildMCP)
Expected: Build Succeeded

**Step 6: Commit**

```
git add -A app/Kokukoku/Kokukoku.xcodeproj/project.pbxproj
git add -A app/Kokukoku/KokukokuWidget/Info.plist
git commit -m "fix: switch Widget to generated Info.plist"
```

---

### Task 4: Consolidate ActivityAttributes

Remove duplicate and point Widget's source reference to the shared file.

**Files:**
- Modify: `app/Kokukoku/Kokukoku.xcodeproj/project.pbxproj`
- Modify: `app/Kokukoku/Kokukoku/Shared/LiveActivity/KokukokuActivityAttributes.swift`
- Delete: `app/Kokukoku/KokukokuWidget/KokukokuActivityAttributes.swift`

**Step 1: Remove `#if` guard from shared ActivityAttributes**

Change `app/Kokukoku/Kokukoku/Shared/LiveActivity/KokukokuActivityAttributes.swift` from:
```swift
import Foundation

#if os(iOS) && canImport(ActivityKit)
    import ActivityKit

    struct KokukokuActivityAttributes: ActivityAttributes {
        struct ContentState: Codable, Hashable {
            var sessionTitle: String
            var timerStateRaw: String
            var endDate: Date?
        }

        var activityTitle: String
    }
#endif
```
to:
```swift
import ActivityKit
import Foundation

struct KokukokuActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var sessionTitle: String
        var timerStateRaw: String
        var endDate: Date?
    }

    var activityTitle: String
}
```

**Step 2: Update PBXFileReference to point to shared file**

Change the file reference `6AF7D4ACFB280491340A2F8D` from:
```
6AF7D4ACFB280491340A2F8D /* KokukokuActivityAttributes.swift */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; name = KokukokuActivityAttributes.swift; path = KokukokuWidget/KokukokuActivityAttributes.swift; sourceTree = "<group>"; };
```
to:
```
6AF7D4ACFB280491340A2F8D /* KokukokuActivityAttributes.swift */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; name = KokukokuActivityAttributes.swift; path = Kokukoku/Shared/LiveActivity/KokukokuActivityAttributes.swift; sourceTree = "<group>"; };
```

**Step 3: Remove from KokukokuWidget group**

In KokukokuWidget group (`84A30BC9C4D4764D6BB91AFF`), remove:
```
6AF7D4ACFB280491340A2F8D /* KokukokuActivityAttributes.swift */,
```

The PBXBuildFile `861CF750956887E2B7870A0A` in Widget's Sources phase stays — it references the same file ref, now pointing to the shared path.

**Step 4: Delete duplicate file**

```bash
rm app/Kokukoku/KokukokuWidget/KokukokuActivityAttributes.swift
```

**Step 5: Build for iOS Simulator**

Run: `build_sim` (XcodeBuildMCP)
Expected: Build Succeeded

**Step 6: Commit**

```
git add app/Kokukoku/Kokukoku.xcodeproj/project.pbxproj
git add app/Kokukoku/Kokukoku/Shared/LiveActivity/KokukokuActivityAttributes.swift
git add app/Kokukoku/KokukokuWidget/KokukokuActivityAttributes.swift
git commit -m "refactor: consolidate ActivityAttributes to single shared source"
```

---

### Task 5: Update scheme to build extensions

Add Watch and Widget to the build list so `xcodebuild -scheme Kokukoku` compiles all targets.

**Files:**
- Modify: `app/Kokukoku/Kokukoku.xcodeproj/xcshareddata/xcschemes/Kokukoku.xcscheme`

**Step 1: Add KokukokuWatch and KokukokuWidget to BuildActionEntries**

After the existing Kokukoku BuildActionEntry (line 23), add two new entries:
```xml
<BuildActionEntry
   buildForTesting = "YES"
   buildForRunning = "YES"
   buildForProfiling = "YES"
   buildForArchiving = "YES"
   buildForAnalyzing = "YES">
   <BuildableReference
      BuildableIdentifier = "primary"
      BlueprintIdentifier = "3DAD69EFBDEBAA0257C5C10D"
      BuildableName = "KokukokuWatch.app"
      BlueprintName = "KokukokuWatch"
      ReferencedContainer = "container:Kokukoku.xcodeproj">
   </BuildableReference>
</BuildActionEntry>
<BuildActionEntry
   buildForTesting = "YES"
   buildForRunning = "YES"
   buildForProfiling = "YES"
   buildForArchiving = "YES"
   buildForAnalyzing = "YES">
   <BuildableReference
      BuildableIdentifier = "primary"
      BlueprintIdentifier = "E559E32C2B7822C9A8FD55FB"
      BuildableName = "KokukokuWidget.appex"
      BlueprintName = "KokukokuWidget"
      ReferencedContainer = "container:Kokukoku.xcodeproj">
   </BuildableReference>
</BuildActionEntry>
```

**Step 2: Build for iOS Simulator**

Run: `build_sim` (XcodeBuildMCP)
Expected: Build Succeeded (all targets compile)

**Step 3: Commit**

```
git add app/Kokukoku/Kokukoku.xcodeproj/xcshareddata/xcschemes/Kokukoku.xcscheme
git commit -m "chore: add Watch and Widget targets to scheme build list"
```

---

### Task 6: Full verification

Run all verification gates from the design doc.

**Files:** None (verification only)

**Step 1: macOS build**

Run: `make build-macos`
Expected: Build Succeeded

**Step 2: macOS unit tests**

Run: `make test-macos`
Expected: Test Succeeded (22 tests pass)

**Step 3: iOS Simulator build**

Run: `build_sim` (XcodeBuildMCP)
Expected: Build Succeeded

**Step 4: iOS Simulator unit tests**

Run: `test_sim` with `extraArgs: ["-only-testing:KokukokuTests"]`
Expected: Test Succeeded (22 tests pass)

**Step 5: iOS Simulator app launch**

Run: `build_run_sim` (XcodeBuildMCP)
Expected: App installs and launches on iPhone 17 Pro simulator

**Step 6: Commit verification result**

No commit needed if all pass. If any fixes are required, commit them with descriptive messages.
