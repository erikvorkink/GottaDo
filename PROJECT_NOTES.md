# GottaDo Project Notes

## Overview

GottaDo is a native iOS to-do list app built with UIKit, storyboards, and Core Data.
It is intentionally simple and organized around a "1-day sprint" workflow with two task lists:

- Today
- Backlog

Users can:

- create tasks
- rename tasks
- complete and restore tasks
- move tasks between Today and Backlog
- reorder tasks manually
- smart-sort tasks
- flag and unflag tasks
- clear completed tasks from a list
- delete tasks

The app also sets the app icon badge to the count of outstanding Today tasks.

## Product Behavior

### Core interaction model

- Swipe right on a task to complete or restore it.
- Swipe left on a task to move it between Today and Backlog.
- Long-press a task row to flag or unflag it.
- Tap a task to open the edit modal.
- Use the add modal to create a task in Today or Backlog.
- Use reorder mode to drag tasks into a new order.
- Long-press the reorder button to run a "smart sort".

### Smart sort behavior

The current implementation sorts tasks in this order:

1. completed
2. flagged
3. unflagged

Within each group, existing order is preserved because the code rewrites `position` in array order.

### Debug functionality

There is a subtle debug utility button at the left edge of the tab bar.

It currently provides:

- copy all tasks to clipboard in a formatted text layout
- delete old completed tasks
- delete all tasks

## Architecture

### UI stack

- UIKit
- Storyboards
- `UITabBarController` root
- modal add/edit/debug flows presented inside `UINavigationController`
- native `UITabBar` with custom appearance and tuned spacing

This is not a SwiftUI app.

### Persistence

- Core Data via `NSPersistentContainer`
- local on-device database
- no sync layer currently visible

### Main files

- `Source/GottaDo/AppDelegate.swift`
  - app startup
  - Core Data stack
  - badge permission and badge updates

- `Source/GottaDo/Helpers/AppContext.swift`
  - lightweight app-wide persistence and badge interface
  - keeps controllers off the concrete `AppDelegate` type

- `Source/GottaDo/Helpers/TaskNotifications.swift`
  - typed task-list notification names

- `Source/GottaDo/Helpers/TaskModalFactory.swift`
  - centralizes storyboard-based add/edit modal creation
  - wires modal dependencies before presentation

- `Source/GottaDo/TaskList/TaskListViewController.swift`
  - shared task-list behavior
  - swipe actions
  - blank-state and control visibility
  - modal presentation
  - badge refresh

- `Source/GottaDo/TaskList/TaskListService.swift`
  - task fetching
  - reorder persistence
  - move between lists
  - flagging and completion toggles
  - clearing completed tasks
  - smart sort behavior

- `Source/GottaDo/TaskList/TaskTableViewCell.swift`
  - custom task-row layout
  - completion styling
  - old-task badge display
  - flagged accessory display

- `Source/GottaDo/TaskList/TodayViewController.swift`
  - Today-specific list setup

- `Source/GottaDo/TaskList/BacklogViewController.swift`
  - Backlog-specific list setup

- `Source/GottaDo/TaskEdit/TaskAddViewController.swift`
  - create task flow
  - configures modal navigation items

- `Source/GottaDo/TaskEdit/TaskEditViewController.swift`
  - rename and remove task flow
  - configures modal navigation items

- `Source/GottaDo/Debug/DebugViewController.swift`
  - configures debug modal navigation items

- `Source/GottaDo/Helpers/ModalNavigationStyler.swift`
  - shared appearance setup for modal navigation bars

- `Source/GottaDo/CoreData/ManagedContextExtension.swift`
  - fetch helpers
  - counts
  - delete operations

- `Source/GottaDo/CoreData/TaskExtension.swift`
  - task mutation helpers

- `Source/GottaDo/TabBarController.swift`
  - tab bar appearance and spacing
  - debug utility button

- `Source/GottaDo/Debug/DebugTableViewController.swift`
  - debug actions

## Data Model

The Core Data model has one visible entity: `Task`.

Important fields:

- `name`
- `details`
- `flagged`
- `completed`
- `completedDate`
- `createdDate`
- `removed`
- `removedDate`
- `position`
- `taskListId`

### Notes about the model

- `details` exists in the schema but is not currently exposed in the UI.
- Normal task deletion appears to be soft delete via `removed = true`.
- Bulk debug deletion uses batch delete.
- List membership is encoded with `taskListId`.
- Ordering is encoded with `position`.

## Project Configuration Snapshot

- Swift 5.0
- iOS deployment target: 15.0
- UIKit + storyboard app
- Supports iPhone and iPad target families
- Light mode forced in `Info.plist`
- Portrait-only on iPhone
- No third-party dependency manager is present

## Testing Status

The project includes unit and UI test targets, but the current test files are placeholder scaffolds and do not provide meaningful coverage.

## Observed Constraints And Risks

### Codebase shape

- The app is small and understandable.
- Most behavior is concentrated in a few view controllers.
- That makes small changes easy, but larger changes may increase coupling if added directly to existing controllers.

### Technical limitations

- Older UIKit/storyboard architecture
- task list screens still carry older layout assumptions in storyboard constraints and floating controls
- Very limited automated test coverage
- persistence access still defaults through `UIApplication.shared`, but now goes through a lightweight `AppContext` abstraction instead of direct `AppDelegate` reach-through

## Recent Modernization Notes

During April 2026 cleanup work, the app was modernized in a few targeted ways without changing the overall UIKit architecture:

- deployment target raised from iOS 12.2 to iOS 15.0
- modal add/edit/debug flows moved from fake embedded navigation bars to real modal navigation controllers
- shared modal navigation styling moved into `ModalNavigationStyler`
- bottom bar returned to the native `UITabBar` with custom appearance and tuned spacing
- debug access moved from a hidden gesture to a subtle utility button in the tab bar
- task-list row rendering moved from the stock `UITableViewCell` to a custom cell
- task-list mutation logic was split out of `TaskListViewController` into `TaskListService`
- task edit/list/debug controllers now use an `AppContext` abstraction instead of direct `AppDelegate` persistence access
- stringly-typed task notifications were replaced with typed `Notification.Name` constants
- storyboard-based add/edit modal composition was centralized into `TaskModalFactory`

This was intentionally a targeted UIKit modernization, not a SwiftUI migration.

## Environment Notes

During inspection on April 11, 2026, command-line device builds were verified successfully with `xcodebuild`.

Simulator runtime installation or verification may still be unreliable on this machine and should be treated as a separate local environment issue rather than a project-specific problem.

## Useful Repo Contents

- `README.md`
  - user-facing app summary

- `Screenshots/`
  - current product visuals

## Suggested Usage Of This Document

Use this file as the shared snapshot for future enhancement threads.

When a major feature is added or a design decision is made, update:

- current behavior
- constraints
- any architectural decisions worth preserving
