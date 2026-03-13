@preconcurrency import ImageCaptureCore
import AppKit
import PDFKit

enum ScanOutputFormat: String, CaseIterable, Identifiable, Sendable {
    case pdf, jpg, png

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pdf: "PDF"
        case .jpg: "JPG"
        case .png: "PNG"
        }
    }

    var fileExtension: String { rawValue }
}

@MainActor
final class ScannerService: NSObject, ObservableObject {
    enum State: Equatable {
        case idle
        case browsing
        case pickScanner
        case connecting
        case scanning
        case scanned
        case error(String)
    }

    @Published var state: State = .idle
    @Published var scanners: [ICScannerDevice] = []
    @Published var scannedImage: NSImage?
    @Published var scanProgress: Double?

    private var browser: ICDeviceBrowser?
    private var activeScanner: ICScannerDevice?
    private var scanTempDirectory: URL?
    private var browseTimeoutTask: Task<Void, Never>?
    private var progressPollTask: Task<Void, Never>?

    func startBrowsing() {
        state = .browsing
        scanners = []

        let b = ICDeviceBrowser()
        b.delegate = self
        let mask = ICDeviceTypeMask(rawValue:
            ICDeviceTypeMask.scanner.rawValue |
            ICDeviceLocationTypeMask.local.rawValue |
            ICDeviceLocationTypeMask.shared.rawValue |
            ICDeviceLocationTypeMask.bonjour.rawValue
        )!
        b.browsedDeviceTypeMask = mask
        print("[KK] Starting scanner browse with mask: \(mask.rawValue)")
        browser = b
        b.start()
        print("[KK] Browser started, waiting for devices...")

        browseTimeoutTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled, state == .browsing else { return }
            evaluateScanners()
        }
    }

    func selectScanner(_ scanner: ICScannerDevice) {
        browseTimeoutTask?.cancel()
        connectToScanner(scanner)
    }

    func cancelScan() {
        progressPollTask?.cancel()
        activeScanner?.cancelScan()
        stopBrowsing()
        state = .idle
    }

    func reset() {
        stopBrowsing()
        state = .idle
        scannedImage = nil
        scanProgress = nil
    }

    func save(format: ScanOutputFormat, to url: URL) -> Bool {
        guard let image = scannedImage else { return false }

        switch format {
        case .pdf:
            return savePDF(image: image, to: url)
        case .jpg:
            return saveImage(image: image, to: url, type: .jpeg,
                             properties: [.compressionFactor: 0.9])
        case .png:
            return saveImage(image: image, to: url, type: .png, properties: [:])
        }
    }

    // MARK: - Private

    private func evaluateScanners() {
        guard state == .browsing else {
            print("[KK] evaluateScanners called but state is \(state), skipping")
            return
        }

        print("[KK] Evaluating scanners: found \(scanners.count)")
        for (i, s) in scanners.enumerated() {
            print("[KK]   [\(i)] \(s.name ?? "unnamed") — type:\(s.type.rawValue) transport:\(s.transportType ?? "unknown")")
        }

        if scanners.count == 1 {
            connectToScanner(scanners[0])
        } else if scanners.count > 1 {
            state = .pickScanner
        } else {
            state = .error("No scanners found. Make sure your scanner is turned on and connected.")
        }
    }

    private func connectToScanner(_ scanner: ICScannerDevice) {
        print("[KK] Connecting to scanner: \(scanner.name ?? "unnamed")")
        state = .connecting
        activeScanner = scanner
        scanner.delegate = self

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("kk_scan_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        scanTempDirectory = tempDir
        scanner.downloadsDirectory = tempDir
        scanner.transferMode = .fileBased
        print("[KK] Temp dir: \(tempDir.path), requesting open session...")

        scanner.requestOpenSession()
    }

    private func configureScannerAndStart(_ scanner: ICScannerDevice) {
        guard state == .connecting else {
            print("[KK] configureScannerAndStart called but state is \(state), skipping")
            return
        }

        let fu = scanner.selectedFunctionalUnit
        print("[KK] Functional unit: \(fu) type:\(fu.type.rawValue) physicalSize:\(fu.physicalSize)")
        // Pick 300 DPI if supported, otherwise closest available
        let supported = fu.supportedResolutions
        if supported.contains(300) {
            fu.resolution = 300
        } else if let next = supported.integerGreaterThanOrEqualTo(300), next != NSNotFound {
            fu.resolution = next
        } else if let last = supported.sorted().last {
            fu.resolution = last
        }

        fu.pixelDataType = .RGB
        fu.bitDepth = .depth8Bits
        // Cap to US Letter (8.5" x 11") — the bed may report slightly larger (e.g. A4 height)
        let width = min(fu.physicalSize.width, 8.5)
        let height = min(fu.physicalSize.height, 11.0)
        fu.scanArea = CGRect(origin: .zero, size: CGSize(width: width, height: height))
        print("[KK] Configured: resolution=\(fu.resolution) scanArea=\(fu.scanArea) pixelDataType=\(fu.pixelDataType.rawValue)")

        state = .scanning
        scanProgress = 0
        print("[KK] Requesting scan...")
        scanner.requestScan()

        // Poll the functional unit's scanProgressPercentDone
        progressPollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(300))
                let pct = scanner.selectedFunctionalUnit.scanProgressPercentDone
                await MainActor.run { self.scanProgress = max(pct / 100.0, self.scanProgress ?? 0) }
            }
        }
    }

    private func stopBrowsing() {
        progressPollTask?.cancel()
        progressPollTask = nil
        browseTimeoutTask?.cancel()
        browseTimeoutTask = nil

        browser?.stop()
        browser?.delegate = nil
        browser = nil

        if let scanner = activeScanner {
            scanner.cancelScan()
            scanner.requestCloseSession()
            scanner.delegate = nil
        }
        activeScanner = nil
        scanners = []

        if let tempDir = scanTempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
            scanTempDirectory = nil
        }
    }

    private func savePDF(image: NSImage, to url: URL) -> Bool {
        guard let page = PDFPage(image: image) else { return false }
        let doc = PDFDocument()
        doc.insert(page, at: 0)
        return doc.write(to: url)
    }

    private func saveImage(image: NSImage, to url: URL, type: NSBitmapImageRep.FileType,
                           properties: [NSBitmapImageRep.PropertyKey: Any]) -> Bool {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: type, properties: properties) else {
            return false
        }
        do {
            try data.write(to: url)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - ICDeviceBrowserDelegate

extension ScannerService: ICDeviceBrowserDelegate {
    nonisolated func deviceBrowser(_ browser: ICDeviceBrowser, didAdd device: ICDevice, moreComing: Bool) {
        print("[KK] Browser didAdd device: \(device.name ?? "unnamed") type:\(device.type.rawValue) moreComing:\(moreComing)")
        guard let scanner = device as? ICScannerDevice else {
            print("[KK]   Not a scanner, ignoring")
            return
        }
        Task { @MainActor in
            self.scanners.append(scanner)
            if !moreComing && self.state == .browsing {
                self.evaluateScanners()
            }
        }
    }

    nonisolated func deviceBrowser(_ browser: ICDeviceBrowser, didRemove device: ICDevice, moreGoing: Bool) {
        print("[KK] Browser didRemove device: \(device.name ?? "unnamed")")
        Task { @MainActor in
            self.scanners.removeAll { $0 === device }
        }
    }
}

// MARK: - ICScannerDeviceDelegate

extension ScannerService: ICScannerDeviceDelegate {
    nonisolated func device(_ device: ICDevice, didOpenSessionWithError error: (any Error)?) {
        print("[KK] didOpenSession for \(device.name ?? "unnamed") error: \(String(describing: error))")
        Task { @MainActor in
            if let error {
                self.state = .error("Could not connect to scanner: \(error.localizedDescription)")
                return
            }
            // Don't start scan here — wait for didSelect functionalUnit,
            // which fires once the functional unit is fully initialized
            print("[KK] Session open, waiting for functional unit to be ready...")
        }
    }

    nonisolated func device(_ device: ICDevice, didCloseSessionWithError error: (any Error)?) {
        print("[KK] didCloseSession for \(device.name ?? "unnamed") error: \(String(describing: error))")
    }

    nonisolated func didRemove(_ device: ICDevice) {
        print("[KK] didRemove device: \(device.name ?? "unnamed")")
        Task { @MainActor in
            if device === self.activeScanner {
                self.state = .error("Scanner was disconnected.")
                self.activeScanner = nil
            }
        }
    }

    nonisolated func scannerDevice(_ scanner: ICScannerDevice,
                                   didSelect functionalUnit: ICScannerFunctionalUnit,
                                   error: (any Error)?) {
        print("[KK] didSelect functionalUnit type:\(functionalUnit.type.rawValue) error: \(String(describing: error))")
        Task { @MainActor in
            if let error {
                self.state = .error("Scanner error: \(error.localizedDescription)")
                return
            }
            self.configureScannerAndStart(scanner)
        }
    }

    nonisolated func scannerDevice(_ scanner: ICScannerDevice, didScanTo url: URL) {
        print("[KK] didScanTo: \(url.path)")
        Task { @MainActor in
            if let image = NSImage(contentsOf: url) {
                self.scannedImage = image
                self.state = .scanned
                print("[KK] Scan saved to: \(url.path)")
            } else {
                self.state = .error("Could not read the scanned image.")
            }
        }
    }

    nonisolated func scannerDevice(_ scanner: ICScannerDevice,
                                   didCompleteScanWithError error: (any Error)?) {
        print("[KK] didCompleteScan error: \(String(describing: error))")
        Task { @MainActor in
            if let error, self.state == .scanning {
                self.state = .error("Scan failed: \(error.localizedDescription)")
            }
        }
    }
}
