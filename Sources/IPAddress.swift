import Foundation
import Darwin

enum IPAddress {
    static func parse(_ data: Data) -> String? {
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        let address = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var ipv4 = in_addr()
        var ipv6 = in6_addr()
        guard inet_pton(AF_INET, address, &ipv4) == 1 || inet_pton(AF_INET6, address, &ipv6) == 1 else {
            return nil
        }
        return address
    }
}
