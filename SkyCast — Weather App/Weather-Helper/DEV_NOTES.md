# 🧠 SkyCast — Developer Notes

This document provides a deeper technical overview of the SkyCast Weather App.

---

## 🏗️ Architecture

SkyCast follows the **MVVM (Model-View-ViewModel)** architecture:

### View (SwiftUI)
Handles UI rendering and user interaction  
→ `ContentView.swift`

### ViewModel
Manages state, business logic, and data flow  
→ `WeatherViewModel.swift`

### Service Layer
Handles API requests and data fetching  
→ `WeatherService.swift`

### Models
Defines structured weather data  
→ `WeatherModels.swift`

### Location Manager
Handles user location permissions and updates  
→ `LocationManager.swift`

---

## 📂 Project Structure
    SkyCast/
    ├── ContentView.swift
    ├── WeatherViewModel.swift
    ├── WeatherService.swift
    ├── WeatherModels.swift
    ├── LocationManager.swift
    ├── WeatherButton.swift

---

## 🎨 UI Design

- Uses `.ultraThinMaterial` for modern glass effect  
- Dynamic gradients based on weather conditions  
- Reusable UI components (cards, buttons)  
- Optimized for readability in Light & Dark Mode  
- Inspired by Apple’s Weather app design  

---

## ⚙️ How It Works

1. User searches for a city or uses current location  
2. `WeatherViewModel` triggers a data fetch  
3. `WeatherService` calls the Open-Meteo API  
4. Data is mapped into models  
5. SwiftUI updates the UI automatically via bindings  

---

## 🧪 Future Improvements

- 🌙 Day/Night UI based on real sunrise/sunset  
- 🔔 Weather alerts & notifications  
- 🌡️ Unit switching (°C / °F)  
- 📍 Auto-refresh location updates  
- ✨ Enhanced animations and transitions  

---

## 🧠 Developer Notes

- Built entirely with SwiftUI  
- Focused on clean architecture and readability  
- Designed to be easily extendable and maintainable  
- Uses reusable components for scalability
