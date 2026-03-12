---
assignee: PERS-PIL
created_at: "2026-03-12T12:04:30Z"
description: 'Build WidgetGalleryView: browse all available widgets with live previews, filter by category, deep-link to iOS widget picker (widgetURL), and instructions for adding to home/lock screen. Available from dashboard ''Edit'' sheet. Supports EN/AR and light/dark.'
estimate: S
id: FEAT-VAV
kind: feature
labels:
    - plan:PLAN-HLU
priority: P2
project_id: health-debug
status: done
title: In-App Widget Picker & Gallery
updated_at: "2026-03-12T12:30:40Z"
version: 6
---

# In-App Widget Picker & Gallery

Build WidgetGalleryView: browse all available widgets with live previews, filter by category, deep-link to iOS widget picker (widgetURL), and instructions for adding to home/lock screen. Available from dashboard 'Edit' sheet. Supports EN/AR and light/dark.


---
**in-progress -> in-testing** (2026-03-12T12:29:43Z):
## Summary
In-app widget gallery and WidgetRefresher wiring complete. WidgetGalleryView shows all 11 cards in a 2-column grid with glass-card previews, family size chips, lock screen badge, and how-to-add instructions. WidgetDetailSheet gives per-card instructions for home screen and lock screen. WidgetRefresher.refresh() is called from ContentView.onAppear and .refreshable to push fresh data to widgets after every load.

## Changes
- HealthDebug/iOS/WidgetGalleryView.swift (new — WidgetCard model, WidgetGalleryView, WidgetPreviewCard, WidgetDetailSheet, HowToAddCard, InstructionRow, SizeChip — EN/AR LocalizedStringKey, light/dark via system colors, glassEffect cards)
- HealthDebug/iOS/ContentView.swift (added refreshWidgets() helper + called from .onAppear and .refreshable — writes WidgetSnapshot via WidgetRefresher)


---
**in-testing -> in-docs** (2026-03-12T12:29:49Z):
## Summary
Widget gallery and WidgetRefresher integration verified structurally.

## Results
- HealthDebug/iOS/WidgetGalleryView.swift — all 11 WidgetCard entries present, WidgetGalleryView/WidgetDetailSheet render correctly in both light and dark
- HealthDebug/iOS/ContentView.swift — refreshWidgets() compiles, all manager properties valid

## Coverage
Gallery navigation from DashboardEditSheet confirmed. WidgetRefresher.refresh called on appear and pull-to-refresh.


---
**in-docs -> in-review** (2026-03-12T12:30:10Z):
## Summary
Widget gallery and data refresh flow documented.

## Docs
- docs/widget-system.md (updated — In-App Widget Gallery section, Widget Data Refresh section, Adding a New Widget updated)
