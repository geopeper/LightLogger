import SwiftUI
import CoreLocation
import Combine

struct ContentView: View {
    @StateObject private var gps = LocationService()
    @StateObject private var store = LightDataStore()

    @State private var brightnessText: String = ""
    @State private var shareURL: URL?
    @State private var isSharePresented = false
    @State private var shareFilename: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Header: Location summary card
                    locationCard

                    // Input: Brightness capture card
                    inputCard

                    // Actions: Export / Clear
                    actionCard

                    // Footer: Count
                    countRow
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .navigationTitle("光度記錄")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { gps.start() }
        .sheet(isPresented: $isSharePresented) {
            if let url = shareURL {
                ActivityViewController(activityItems: [url])
                    .presentationDetents([.medium, .large])
                    .onDisappear { cleanupTemp(url) }
            }
        }
        .alert("沒有定位資料", isPresented: .constant(showNoLocationAlert)) {
            Button("知道了", role: .cancel) { }
        } message: {
            Text("請確認已開啟 App 的定位權限與精確位置。")
        }
    }

    // MARK: - Cards

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("目前位置")
                        .font(.headline)
                    HStack(spacing: 8) {
                        statusChip(text: authText, color: authColor)
                        statusChip(text: accuracyText, color: accuracyColor)
                    }
                }

                Spacer()

                if gps.location != nil {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .accessibilityLabel("定位可用")
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("尚無定位")
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                row("緯度", latString)
                row("經度", lonString)
                row("水平精度(公尺)", hAccString)
                row("時間", timeString)
            }
            .font(.system(.body, design: .monospaced))
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.orange)
                Text("新增亮度")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    TextField("輸入亮度數值…", text: $brightnessText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .font(.title3.weight(.medium))
                        .padding(.vertical, 12)
                        .padding(.leading, 12)

                    Text("lx")
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )

                Button {
                    saveRecord()
                } label: {
                    Label("存入", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(!canSave)
                .animation(.easeInOut(duration: 0.15), value: canSave)
            }

            if let err = gps.lastError, !err.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22))
                    .foregroundStyle(.indigo)
                Text("匯出 / 管理")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    exportCSV()
                } label: {
                    Label("CSV", systemImage: "doc.text.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(storeIsEmpty)

                Button {
                    exportGeoJSON()
                } label: {
                    Label("GeoJSON", systemImage: "globe.americas.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(storeIsEmpty)

                Button(role: .destructive) {
                    confirmClear()
                } label: {
                    Label("清空", systemImage: "trash.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(storeIsEmpty)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }

    private var countRow: some View {
        HStack(spacing: 8) {
            Text("已記錄")
                .foregroundStyle(.secondary)
            Text("\(storeCount)")
                .font(.headline.monospacedDigit())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.blue.opacity(0.12))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.blue.opacity(0.25), lineWidth: 1)
                )
            Text("筆")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .font(.footnote)
    }

    // MARK: - Status chips

    private func statusChip(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.12))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(color.opacity(0.25), lineWidth: 1)
            )
            .foregroundStyle(color)
    }

    private var authText: String {
        switch gps.authorizationStatus {
        case .authorizedAlways: return "永遠允許"
        case .authorizedWhenInUse: return "使用期間允許"
        case .denied: return "已拒絕"
        case .restricted: return "受限制"
        case .notDetermined: return "未決定"
        @unknown default: return "未知"
        }
    }
    private var authColor: Color {
        switch gps.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return .green
        case .denied, .restricted: return .orange
        case .notDetermined: return .gray
        @unknown default: return .gray
        }
    }
    private var accuracyText: String {
        switch gps.accuracyAuth {
        case .fullAccuracy: return "精確位置"
        case .reducedAccuracy: return "大概位置"
        @unknown default: return "未知精度"
        }
    }
    private var accuracyColor: Color {
        switch gps.accuracyAuth {
        case .fullAccuracy: return .blue
        case .reducedAccuracy: return .purple
        @unknown default: return .gray
        }
    }

    // MARK: - Computed strings
    private var latString: String {
        guard let lat = gps.location?.coordinate.latitude else { return "—" }
        return String(format: "%.6f", lat)
    }
    private var lonString: String {
        guard let lon = gps.location?.coordinate.longitude else { return "—" }
        return String(format: "%.6f", lon)
    }
    private var hAccString: String {
        guard let h = gps.location?.horizontalAccuracy, h.isFinite else { return "—" }
        return String(format: "%.2f", h)
    }
    private var timeString: String {
        guard let ts = gps.location?.timestamp else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.string(from: ts)
    }

    private var canSave: Bool {
        guard gps.location != nil else { return false }
        return Double(brightnessText) != nil
    }
    private var storeIsEmpty: Bool { storeCount == 0 }
    private var storeCount: Int { storeValueCount() }
    private var showNoLocationAlert: Bool { gps.location == nil }

    // MARK: - UI Rows
    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text("\(title)")
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Actions
    private func saveRecord() {
        guard let loc = gps.location, let b = Double(brightnessText) else { return }
        store.add(brightness: b, location: loc)
        brightnessText = ""
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func exportCSV() {
        let pack = store.buildCSV()
        export(data: pack.data, suggestedName: pack.filename)
    }

    private func exportGeoJSON() {
        let pack = store.buildGeoJSON()
        export(data: pack.data, suggestedName: pack.filename)
    }

    private func confirmClear() {
        store.clear()
    }

    private func export(data: Data, suggestedName: String) {
        do {
            let url = try writeTempFile(data: data, filename: suggestedName)
            self.shareURL = url
            self.shareFilename = suggestedName
            self.isSharePresented = true
        } catch {
            print("Export error: \(error)")
        }
    }

    // MARK: - Temp file helpers
    private func writeTempFile(data: Data, filename: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
        try data.write(to: url, options: .atomic)
        return url
    }

    private func cleanupTemp(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func storeValueCount() -> Int {
        return store.records.count
    }
}

// 分享面板
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
