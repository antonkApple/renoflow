import Foundation

extension JSONEncoder {
    static var renoFlow: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var renoFlow: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }

    func hostMatches(_ baseURL: String) -> Bool {
        guard let candidate = URL(string: baseURL)?.host?.replacingOccurrences(of: "www.", with: "").lowercased(),
              let host = host?.replacingOccurrences(of: "www.", with: "").lowercased() else { return false }
        return host == candidate || host.hasSuffix(".\(candidate)")
    }
}

extension String {
    var cleanedHTML: String {
        replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Double {
    var clean: String {
        rounded() == self ? Int(self).formatted() : formatted(.number.precision(.fractionLength(1)))
    }
}
