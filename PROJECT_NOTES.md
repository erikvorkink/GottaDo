# GottaDo Project Notes

## Overview

GottaDo is a native iOS to-do list app built with UIKit, storyboards, and Core Data.
It is intentionally simple and centered on a two-list workflow:

- Today
- Backlog

The app is designed for lightweight daily planning rather than a full project-management system.

## Current Product Behavior

Users can:

- create tasks in Today or Backlog
- rename tasks
- soft-delete tasks
- complete and restore tasks
- move tasks between Today and Backlog
- reorder tasks manually
- smart-sort tasks
- flag and unflag tasks
- clear completed tasks from the current list

The app icon badge shows the count of outstanding visible tasks in Today.

### Task interactions

- Tap a task row to open the edit modal.
- Tapping outside the edit modal saves changes and closes it.
- Swipe right to complete or restore a task.
- Swipe left to move a task between Today and Backlog.
- Long-press a task row to flag or unflag it.
- Tap the add button to create a new task.
- In the add modal, tapping Today or Backlog with a populated task name creates the task in that selected list.
- Tap the reorder button to enter drag-reorder mode.
- Long-press the reorder button to run smart sort.
- Tap the clear button to soft-delete completed tasks in the current list.

### List behavior

- New tasks created in Today are appended to the end of Today.
- New tasks created in Backlog are inserted at the top of Backlog and shift existing Backlog items down.
- Moving a task from Backlog to Today appends it to the end of Today.
- Moving a task from Today to Backlog inserts it at the top of Backlog and shifts existing Backlog items down.
- Reordering persists by rewriting each task's `position`.
- The reorder button is hidden when a list has fewer than two visible tasks.
- The clear button is hidden unless the current list contains completed tasks.
- Empty lists show a "Nothing to do" blank state.

### Smart sort behavior

Smart sort groups tasks in this order:

1. completed
2. flagged and not completed
3. unflagged and not completed

Within each group, relative order is preserved.

### Row presentation

- Completed tasks remain visible until cleared.
- Flagged tasks show a visual flagged state in the custom table cell.
- Tasks older than six months are marked as old tasks in the row UI.

### Maintenance tools

A subtle maintenance button is installed at the left edge of the tab bar.

The maintenance screen currently provides:

- copy tasks to the clipboard in a formatted Today / Backlog / Completed layout
- show a read-only `Recently Cleared` list of the 30 most recently cleared completed items
- delete completed tasks older than 90 days with a batch delete
- delete all tasks with a batch delete

## Architecture

### UI stack

- UIKit
- storyboards
- `UITabBarController` root
- modal add, edit, and maintenance flows presented in `UINavigationController`
- custom list-screen layout built in code inside storyboard-backed controllers

This is not a SwiftUI app.

### Main app structure

- `Source/GottaDo/AppDelegate.swift`
  - app entry point
  - Core Data stack
  - badge authorization and badge updates

- `Source/GottaDo/Helpers/AppContext.swift`
  - app-wide interface for persistence and badge updates
  - keeps most controllers off the concrete `AppDelegate` type

- `Source/GottaDo/Helpers/TaskModalFactory.swift`
  - centralizes storyboard-based modal creation
  - injects dependencies before presentation

- `Source/GottaDo/Helpers/TaskNotifications.swift`
  - typed notification names for list refreshes

- `Source/GottaDo/Helpers/ModalNavigationStyler.swift`
  - shared modal navigation bar styling

- `Source/GottaDo/TabBarController.swift`
  - tab bar appearance and spacing
  - maintenance button installation

- `Source/GottaDo/TaskList/TaskListViewController.swift`
  - shared list behavior
  - layout, blank state, swipe actions, modal presentation, reorder mode, badge refresh

- `Source/GottaDo/TaskList/TaskListService.swift`
  - task-list mutations and ordering rules

- `Source/GottaDo/TaskList/TaskTableViewCell.swift`
  - custom task row rendering

- `Source/GottaDo/TaskList/TodayViewController.swift`
  - Today-specific configuration

- `Source/GottaDo/TaskList/BacklogViewController.swift`
  - Backlog-specific configuration

- `Source/GottaDo/TaskEdit/TaskAddViewController.swift`
  - add-task flow

- `Source/GottaDo/TaskEdit/TaskEditViewController.swift`
  - rename and remove flow

- `Source/GottaDo/Maintenance/MaintenanceViewController.swift`
  - maintenance modal container

- `Source/GottaDo/Maintenance/MaintenanceTableViewController.swift`
  - maintenance actions
  - recently cleared history list

### Persistence

- Core Data via `NSPersistentContainer`
- local on-device database
- no sync layer
- no networking layer in the app target

## Data Model

The main persisted entity is `Task`.

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

### Model notes

- `details` exists in the schema but is not exposed in the current UI.
- Normal task deletion is a soft delete via `removed = true` and `removedDate`.
- Completed-task clearing also uses soft delete.
- The maintenance `Recently Cleared` list is powered by `removedDate`, sorted most recent first.
- Maintenance bulk deletion uses `NSBatchDeleteRequest`.
- List membership is encoded with `taskListId`.
- Ordering is encoded with `position`.

## Project Configuration

- Swift 5
- iOS deployment target: 15.0
- bundle identifier: `com.erikvorkink.GottaDoApp`
- marketing version: `1.0.1`
- supports iPhone and iPad target families
- portrait-only on iPhone
- light mode forced in `Info.plist`
- no third-party dependency manager is present

## Tests And Validation

The project has both unit and UI test targets.

Current test coverage is still light, but it is no longer just placeholder scaffolding:

- `Source/GottaDoTests/GottaDoTests.swift` covers `TaskListService`
- covered behaviors include move ordering, smart sort grouping, and completed-task removal
- `Source/GottaDoUITests/GottaDoUITests.swift` is still a minimal launch-style smoke test

## Constraints And Risks

- The app is small and understandable, but key behavior is still concentrated in a few view controllers.
- The architecture is intentionally UIKit-and-storyboard based, so changes should preserve that direction unless there is an explicit migration decision.
- Automated coverage exists but is still narrow relative to the amount of UI behavior.
- Persistence helpers still use KVC-style field mutation on `Task`, which keeps the code compact but is easier to break during model changes.
- There is no sync, account system, or server-backed recovery path.

## Useful Repo Contents

- `README.md`
  - user-facing app summary

- `Screenshots/`
  - product visuals

- `Artwork/`
  - app icon, logo, and custom control assets

## What To Keep Updated

When the app changes in meaningful ways, update this file with:

- current user-visible behavior
- architecture decisions worth preserving
- data-model or persistence changes
- testing reality and known risks
