import Foundation
import CoreLocation
import Combine

struct LightRecord: Identifiable, Codable {
    let id = UUID()
    let index: Int
    let latitude: Double
    let longitude: Double
    let hAccuracy: Double
    let timestampISO: String
    let brightness: Double
}

final class LightDataStore: ObservableObject {
    @Published private(set) var records: [LightRecord] = []
    private let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    func add(brightness: Double, location: CLLocation) {
        let nextIndex = records.count + 1
        let rec = LightRecord(
            index: nextIndex,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            hAccuracy: location.horizontalAccuracy,
            timestampISO: iso.string(from: location.timestamp),
            brightness: brightness
        )
        records.append(rec)
    }

    func clear() {
        records.removeAll()
    }

    // MARK: - Export

    func buildCSV() -> (filename: String, data: Data) {
        var lines: [String] = []
        lines.append("index,latitude,longitude,h_accuracy_m,timestamp_iso,brightness")
        for r in records {
            let line = "\(r.index),\(fmt(r.latitude)),\(fmt(r.longitude)),\(fmt(r.hAccuracy))," +
                       "\(r.timestampISO),\(fmt(r.brightness))"
            lines.append(line)
        }
        let csv = lines.joined(separator: "\n")
        return ("light_gps_\(dateStamp()).csv", Data(csv.utf8))
    }

    func buildGeoJSON() -> (filename: String, data: Data) {
        // Minimal FeatureCollection
        var features: [[String: Any]] = []
        for r in records {
            let feat: [String: Any] = [
                "type": "Feature",
                "geometry": [
                    "type": "Point",
                    "coordinates": [r.longitude, r.latitude]  // GeoJSON: [lon, lat]
                ],
                "properties": [
                    "index": r.index,
                    "brightness": r.brightness,
                    "timestamp": r.timestampISO,
                    "h_accuracy_m": r.hAccuracy
                ]
            ]
            features.append(feat)
        }
        let fc: [String: Any] = [
            "type": "FeatureCollection",
            "features": features
        ]
        let data = try! JSONSerialization.data(withJSONObject: fc, options: [.prettyPrinted])
        return ("light_gps_\(dateStamp()).geojson", data)
    }

    // MARK: - Helpers
    private func fmt(_ v: Double) -> String {
        if v.isNaN || !v.isFinite { return "" }
        if abs(v) >= 1 { return String(format: "%.6f", v) }
        return String(format: "%.8f", v)
    }
    private func dateStamp() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd_HHmmss"
        return df.string(from: Date())
    }
}
