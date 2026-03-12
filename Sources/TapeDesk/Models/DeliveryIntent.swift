import Foundation

enum DeliveryIntent: String, CaseIterable, Sendable, Identifiable {
    case email
    case message
    case socialMedia
    case cloudUpload
    case general

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .email: "Email"
        case .message: "Message / Text"
        case .socialMedia: "Social Media"
        case .cloudUpload: "Cloud Upload"
        case .general: "General Sharing"
        }
    }

    var description: String {
        switch self {
        case .email: "Optimized for email attachments (smaller file size)"
        case .message: "Quick sharing via Messages or similar"
        case .socialMedia: "Ready for social media upload"
        case .cloudUpload: "Balanced quality for cloud storage"
        case .general: "Good quality, reasonable size"
        }
    }
}
