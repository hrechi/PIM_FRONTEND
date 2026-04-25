# Fieldly Mobile App Summary

## Purpose and Product Context
Fieldly is a smart farm mobile app that combines field operations, weather intelligence, AI-assisted crop care, livestock management, security monitoring, and worker material operations in one interface.

The app currently exposes role-based experiences:
- Owner experience (main dashboard + advanced farm/security/livestock modules)
- Worker experience (materials and equipment workflow + focused navigation)

A Control Room module is available as a shared operations feature for both roles.

## Main Home Screen (Owner) - Current Feature Set
The owner home dashboard currently includes:
- Parcel selection and context switching
- Unified farm status card with farm mood, score, and dynamic plant message
- Quick actions:
  - Fields
  - Missions
  - Assistant
  - Assets
  - Control Room
  - See Map
- Weather chips (wind, temperature delta, humidity)
- Soil and crop health cards
- Weather and Advice smart card (current conditions, humidity, wind, rain)
- Farm Reels preview card
- Livestock intelligence panels:
  - Live Health Metrics section
  - Animal stats cards (total animals, health alerts, vaccines due, monthly spend)
  - Milk production banner with trend vs previous day
  - Horizontal animal metric cards
- Floating chat assistant shortcut button
- Real-time alert behavior (soil alert notifications and security overlay handling)

## Home Drawer (Owner) - Feature Inventory
The owner drawer from the main home screen currently groups features as follows.

### Farm
- My Parcels
- AI Plant Doctor
- Harvest Analytics
- Crop Calendar
- Weather and Advice
- Agricultural News
- Farm Reels
- Community Feed
- Irrigation Scheduler
- Soil Measurements
- Farm Quiz

### Security
- Security Whitelist
- Add Staff
- Incident History
- Live Feed
- Daily Reports (AI security digest)
- Acoustic Monitor (sound threat detection)

### Operations
- Control Room

### Animals
- Animal List
- Add Animal
- Milk Production
- Milk Analytics
- Vaccine Dashboard

### Account
- Profile
- Settings

## Worker Home Screen - Current Feature Set
The worker dashboard currently includes:
- Greeting card for signed-in worker
- Active material session card with elapsed timer
- Quick stats cards:
  - Available materials
  - Animals
  - Active sessions
- Control Room quick action button
- Material management flow:
  - Start using material
  - Select material from assigned list
  - Start session and check-in workflow
- Assigned materials and equipment list
- Animals section for assigned field context
- Pull-to-refresh dashboard behavior

## Worker Drawer - Feature Inventory
Worker drawer navigation currently includes:
- Home (worker dashboard)
- Profile
- Control Room
- Sign Out

## Shared App Drawer Coverage in Other Screens
A shared drawer implementation is also present in the app and provides broad owner navigation coverage including:
- Farm modules (parcels, soil health, AI Plant Doctor, harvest analytics, Aero-Twin NDVI, crop calendar, weather, irrigation, news, reels, community)
- Livestock module with expandable animal management:
  - Livestock dashboard
  - Livestock list
  - Add new animal
  - Milk analytics
  - Milk production
  - Vaccination
- Security modules (whitelist, add staff, incident history, live feed)
- Operations (Control Room)
- Account (profile, settings)

## Current Navigation and Experience Notes
- Control Room is now exposed from:
  - Owner home quick actions
  - Owner drawer operations section
  - Worker home quick action
  - Worker drawer
- Owner and worker dashboards are intentionally different:
  - Owner focuses on full-farm intelligence and multi-domain controls.
  - Worker focuses on daily material/equipment operations with quick operational access.

## Summary
Fieldly already has a broad, production-style feature surface across farm, weather, AI diagnosis, irrigation, livestock, security, and worker workflows. The current mobile experience is role-aware, module-rich, and now includes robot operations entry points through Control Room for both owner and worker journeys.
