# Safe Mode Nutrition Logger

## Overview

Boolean safe/unsafe meal tracking — no calorie counting. Uses a blacklist/whitelist system to classify foods against three health conditions: IBS/GERD, Gout, and Fatty Liver.

## How It Works

1. **Quick Log** — Tap a safe food from the whitelist (proteins, carbs, fats) for instant logging
2. **Custom Log** — Tap + to enter any food name; auto-classified against the blacklist in real-time
3. **Safety Score** — Percentage of safe meals today (100% = all safe, lower = triggers hit)
4. **Trigger Warnings** — Shows which health systems are at risk from unsafe foods logged today
5. **Shutdown Integration** — Warning banner when GERD shutdown window is active

## Architecture

### NutritionManager (`HealthDebugKit/Health/NutritionManager.swift`)

`@MainActor` singleton:

- `logSafeMeal()` — whitelist items, no classification needed
- `logMeal()` — auto-classifies via `FoodRegistry.classify()`
- `safetyScore` — percentage of safe meals
- `todayTriggers` — set of unique trigger types hit today

### FoodRegistry (`HealthDebugKit/Protocols/FoodRegistry.swift`)

Static classification engine:

**Blacklist (triggers):**
- IBS/GERD: Whole Eggs, Falafel, Deep Fried Foods, Raw Onion, Raw Garlic, Cheddar/Yellow Cheese
- Gout: Red Meat, Liver, Duck, Beans, Lentils, Legumes
- Fatty Liver: Refined Sugar, Honey, Nutella, Jam, White Flour, Mixed Carbs

**Whitelist (safe):**
- Proteins: Grilled Chicken Breast, White Fish, Cottage Cheese, Greek Yogurt
- Carbs: Oats, Whole Wheat Toast, White Rice, Brown Rice
- Fats: Olive Oil, Avocado

### NutritionView (`HealthDebug/iOS/NutritionView.swift`)

- Safety score ring with color-coded status
- Quick-log horizontal scroll rows by category
- Triggers card (red) when unsafe meals logged
- Custom log sheet with live classification preview
- Shutdown warning banner

## Data Model

`MealLog` (`HealthDebugKit/Models/MealLog.swift`):
- `name: String`
- `category: String` (protein, carb, fat, drink, snack)
- `isSafe: Bool`
- `triggers: [String]` (IBS/GERD, Gout, Fatty Liver)
- `timestamp: Date`
- `notes: String`

## Safety Statuses

| Status | Condition |
|--------|-----------|
| All Safe | No unsafe meals today |
| Warning | 1 unsafe meal |
| Critical | 2+ unsafe meals |
| No Meals | Nothing logged yet |
