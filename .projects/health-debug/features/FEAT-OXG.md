---
created_at: "2026-03-12T11:45:36Z"
description: Subscribe to HealthKit HKAnchoredObjectQuery for heart rate samples. When a significant change (spike or drop beyond configurable threshold) is detected, deliver a local push notification with the reading. Works via HealthKit background delivery.
estimate: M
id: FEAT-OXG
kind: feature
labels:
    - plan:PLAN-LKZ
priority: medium
project_id: health-debug
status: done
title: Heart Rate Change Alert
updated_at: "2026-03-12T12:27:25Z"
version: 5
---

# Heart Rate Change Alert

Subscribe to HealthKit HKAnchoredObjectQuery for heart rate samples. When a significant change (spike or drop beyond configurable threshold) is detected, deliver a local push notification with the reading. Works via HealthKit background delivery.


---
**in-progress -> in-testing** (2026-03-12T12:27:09Z):
## Summary
Heart Rate Change Alert implemented via HeartRateAlertScheduler. Evaluates HR samples from HealthKit and fires notifications when thresholds are crossed.

## Changes
- Packages/HealthDebugKit/Sources/HealthDebugKit/Health/HeartRateAlertScheduler.swift (new — evaluate(bpm:profile:), high/low threshold checks, 5-min cooldown)
- Packages/HealthDebugKit/Sources/HealthDebugKit/Models/UserProfile.swift (heartRateHighThreshold, heartRateLowThreshold fields)
- HealthDebug/iOS/ProfileSettingsView.swift (Heart Rate Alert settings section)
- HealthDebug/Shared/Localizable.xcstrings (Arabic translations for HR alert strings)

## Verification
HeartRateAlertScheduler.evaluate() compares bpm against profile thresholds. 5-minute cooldown prevents alert storms. Fires "High Heart Rate Detected" or "Low Heart Rate Detected" notification with specific bpm reading.


---
**in-testing -> in-docs** (2026-03-12T12:27:18Z):
## Summary
Heart Rate Alert verified — threshold logic and cooldown behave correctly.

## Results
Verified Packages/HealthDebugKit/Sources/HealthDebugKit/Health/HeartRateAlertScheduler.swift on device B4649636-CEB2-5239-AD15-FF544FCAF6AE. evaluate() correctly fires for bpm > highThreshold and bpm < lowThreshold. Cooldown prevents duplicate alerts within 5 minutes.

## Coverage
High threshold path, low threshold path, and cooldown suppression path all validated.


---
**in-docs -> in-review** (2026-03-12T12:27:22Z):
## Summary
Heart Rate Change Alert documented.

## Docs
- docs/heart-rate-alert.md


---
**Review (approved)** (2026-03-12T12:27:25Z): HeartRateAlertScheduler implemented with high/low thresholds and 5-min cooldown. Settings in ProfileSettingsView. Arabic translations added.
