import Foundation

enum ItemParser {
    static func parse(url: URL, storeName: String) async -> ParsedItemDraft {
        var html = ""
        if let (data, _) = try? await URLSession.shared.data(from: url), let body = String(data: data, encoding: .utf8) {
            html = body
        }
        let title = ogValue("title", in: html) ?? htmlTitle(in: html) ?? url.lastPathComponent.replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "_", with: " ").capitalized
        return ParsedItemDraft(
            title: title.cleanedHTML,
            imageURL: ogValue("image", in: html),
            price: price(in: html),
            productURL: url.absoluteString,
            storeName: storeName
        )
    }

    private static func ogValue(_ property: String, in html: String) -> String? {
        let patterns = [
            "<meta[^>]+property=[\"']og:\(property)[\"'][^>]+content=[\"']([^\"']+)[\"'][^>]*>",
            "<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+property=[\"']og:\(property)[\"'][^>]*>"
        ]
        return firstMatch(patterns, in: html)
    }

    private static func htmlTitle(in html: String) -> String? {
        firstMatch(["<title[^>]*>(.*?)</title>"], in: html)
    }

    private static func price(in html: String) -> Double? {
        let patterns = [
            "<meta[^>]+property=[\"']product:price:amount[\"'][^>]+content=[\"']([0-9]+(?:\\.[0-9]+)?)[\"'][^>]*>",
            "<meta[^>]+content=[\"']([0-9]+(?:\\.[0-9]+)?)[\"'][^>]+property=[\"']product:price:amount[\"'][^>]*>",
            #"[$€£]\s*([0-9]+(?:[,.][0-9]{2})?)"#
        ]
        guard let value = firstMatch(patterns, in: html)?.replacingOccurrences(of: ",", with: ".") else { return nil }
        return Double(value)
    }

    private static func firstMatch(_ patterns: [String], in html: String) -> String? {
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { continue }
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            guard let match = regex.firstMatch(in: html, range: range), match.numberOfRanges > 1,
                  let valueRange = Range(match.range(at: 1), in: html) else { continue }
            return String(html[valueRange]).cleanedHTML
        }
        return nil
    }
}
