# LightLogger

LightLogger is an iOS application for collecting geographic data with precise GPS coordinates and user-provided brightness values. The app allows field data collection and supports exporting records for later analysis.

## Screenshots
![IMG_5738](https://github.com/user-attachments/assets/e57edd78-158b-4aab-9ad2-e9a5f8e17187)

## Features
- Get precise GPS coordinates (latitude, longitude, accuracy, timestamp)
- Input brightness values manually
- Save current GPS + brightness record
- Export all records as CSV or GeoJSON
- Clear records to start a new dataset

## Project Structure
LightLogger/
├── LightLogger.xcodeproj # Xcode project
├── LightLogger/ # Main application code
│ ├── Assets.xcassets # App icons and assets
│ ├── ContentView.swift # Main user interface
│ ├── LightDataStore.swift # Data storage and export logic
│ ├── LocationService.swift # GPS location service
│ ├── PreciseGPSApp.swift # App entry point
│ └── LightLogger-Info.plist # App configuration and permissions

## Usage
1. Open the project in Xcode.
2. Build and run the app on a real iOS device (GPS required).
3. Enter brightness values and save records.
4. Export collected data as CSV or GeoJSON for further use.

## Data in QGIS
<img width="1256" height="780" alt="Screenshot 2025-09-22 at 11 52 09 PM" src="https://github.com/user-attachments/assets/0ef2b8d5-b07c-4d58-ada5-32bd0e368100" />


