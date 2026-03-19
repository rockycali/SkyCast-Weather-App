🌤️ SkyCast — Weather App

📱 Overview

Add "How to Run" (VERY important for recruiters)

Add this section:

```md
## ▶️ How to Run

1. Clone the repository
2. Open the project in Xcode
3. Build and run on simulator or device

Requirements:
- Xcode 15+
- iOS 17+

## 📸 Screenshots

| Light Mode | Dark Mode |
|-----------|-----------|
| ![Light Mode](screenshots/light.png) | ![Dark Mode](screenshots/dark.png) |

------------------------------------------------------------------------------------------

SkyCast is a modern SwiftUI weather application that provides real-time weather data, hourly forecasts, and a 5-day outlook.

The app is designed with a clean, Apple-inspired UI and focuses on smooth animations, readability, and dynamic visuals based on weather conditions.

🚀 Features
    •    🌍 Search weather by city name
    •    📍 Get weather using current location
    •    🌡️ Current temperature and condition summary
    •    📊 Key metrics (Feels Like, Wind, Humidity, Rain)
    •    🌅 Sunrise & Sunset tracking with daylight progress
    •    ⏱️ Hourly forecast
    •    📅 5-day forecast
    •    🎨 Dynamic background gradients based on weather
    •    🌙 Full Light Mode & Dark Mode support

------------------------------------------------------------------------------------------

🏗️ Architecture

SkyCast follows the MVVM (Model-View-ViewModel) architecture:
    •    View (SwiftUI)
Handles UI rendering and user interaction
→ ContentView.swift
    •    ViewModel
Manages state, business logic, and data flow
→ WeatherViewModel.swift
    •    Service Layer
Handles API requests and data fetching
→ WeatherService.swift
    •    Models
Defines structured weather data
→ WeatherModels.swift
    •    Location Manager
Handles user location permissions and updates
→ LocationManager.swift

------------------------------------------------------------------------------------------

📂 Project Structure
    ```bash
    SkyCast/
    ├── ContentView.swift
    ├── WeatherViewModel.swift
    ├── WeatherService.swift
    ├── WeatherModels.swift
    ├── LocationManager.swift
    ├── WeatherButton.swift

------------------------------------------------------------------------------------------

🌐 API

This app uses:
    •    Open-Meteo API
https://open-meteo.com/

✔ No API key required
✔ Fast and reliable weather data

------------------------------------------------------------------------------------------

🎨 UI Design
    •    Uses .ultraThinMaterial for modern glass effect
    •    Dynamic gradients change based on weather conditions
    •    Custom reusable components (cards, buttons)
    •    Carefully tuned opacity for readability in dark mode
    •    Designed to feel similar to Apple’s Weather app
    
------------------------------------------------------------------------------------------

⚙️ How It Works
    1.    User searches for a city or taps “Use My Location”
    2.    WeatherViewModel triggers a fetch request
    3.    WeatherService retrieves data from the API
    4.    Data is mapped into models
    5.    SwiftUI updates the UI automatically via bindings

------------------------------------------------------------------------------------------

🧪 Future Improvements
    •    🌙 Day/Night UI based on real sunrise/sunset
    •    🔔 Weather alerts & notifications
    •    🌡️ Unit switching (°C / °F)
    •    📍 Auto-refresh location updates
    •    ✨ Enhanced animations and transitions
    
------------------------------------------------------------------------------------------
    
🧠 Developer Notes
    •    Built entirely with SwiftUI
    •    Focused on clean architecture and readability
    •    Designed to be easily extendable and maintainable
    •    Includes reusable UI components for scalability

------------------------------------------------------------------------------------------

👨‍💻 Author

Rocky
iOS Developer 🚀
