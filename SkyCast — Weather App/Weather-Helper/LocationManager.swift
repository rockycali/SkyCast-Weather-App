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
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func requestLocation() {

        switch manager.authorizationStatus {
        case .notDetermined:
            errorMessage = nil
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            errorMessage = nil
            manager.startUpdatingLocation()
        case .restricted:
            errorMessage = "Location access is restricted on this device."
        case .denied:
            errorMessage = "Location permission is turned off. Enable it in iPhone Settings > Privacy & Security > Location Services."
        @unknown default:
            errorMessage = "Location access is unavailable right now."
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            errorMessage = nil
            manager.startUpdatingLocation()
        case .restricted:
            errorMessage = "Location access is restricted on this device."
        case .denied:
            errorMessage = "Location permission is turned off. Enable it in iPhone Settings > Privacy & Security > Location Services."
        case .notDetermined:
            break
        @unknown default:
            errorMessage = "Location access is unavailable right now."
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        errorMessage = nil
        lastLocation = locations.last
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
        print("Location error: \(error.localizedDescription)")
    }
}
