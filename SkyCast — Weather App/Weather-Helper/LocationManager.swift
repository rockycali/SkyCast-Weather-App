import CoreLocation
import Foundation

final class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var lastLocation: CLLocation?
    @Published var errorMessage: String?

    private let manager = CLLocationManager()

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func requestLocation() {
        print("📍 requestLocation tapped")

        switch manager.authorizationStatus {
        case .notDetermined:
            print("📍 requesting permission")
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 requesting actual location")
            manager.requestLocation()

        case .denied, .restricted:
            errorMessage = "Location permission denied."

        @unknown default:
            break
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 authorization changed:", manager.authorizationStatus.rawValue)

        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            DispatchQueue.main.async {
                self.errorMessage = nil
            }
            print("📍 auto-requesting location after permission granted")
            manager.requestLocation()

        case .restricted:
            DispatchQueue.main.async {
                self.errorMessage = "Location access is restricted on this device."
            }

        case .denied:
            DispatchQueue.main.async {
                self.errorMessage = "Location permission is turned off. Enable it in iPhone Settings > Privacy & Security > Location Services."
            }

        case .notDetermined:
            break

        @unknown default:
            DispatchQueue.main.async {
                self.errorMessage = "Location access is unavailable right now."
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📍 didUpdateLocations:", location.coordinate.latitude, location.coordinate.longitude)

        DispatchQueue.main.async {
            self.errorMessage = nil
            self.lastLocation = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
        print("📍 location failed:", error.localizedDescription)
    }
}
