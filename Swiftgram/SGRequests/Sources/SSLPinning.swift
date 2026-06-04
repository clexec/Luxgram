import Foundation
import Security
import CryptoKit

/// SSL certificate pinning for URLSession. Pins SHA256 of server certificate (base64).
/// For Let's Encrypt: update the pin when the cert renews (~90 days), or pin multiple certs for rotation.

public final class SSLPinningDelegate: NSObject, URLSessionDelegate {
    private let host: String
    private let pinnedHashes: Set<String>

    /// - Parameters:
    ///   - host: Expected host (e.g. "glegram.site"). Must match the request's host.
    ///   - pinnedHashes: Set of base64-encoded SHA256 hashes of the server certificate(s).
    ///     Generate: `openssl s_client -servername HOST -connect HOST:443 </dev/null 2>/dev/null | openssl x509 -outform DER | openssl dgst -sha256 -binary | base64`
    public init(host: String, pinnedHashes: [String]) {
        self.host = host.lowercased()
        self.pinnedHashes = Set(pinnedHashes.map { $0.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespacesAndNewlines) })
    }

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              challenge.protectionSpace.host.lowercased() == host else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard SecTrustEvaluateWithError(serverTrust, nil) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let certCount = SecTrustGetCertificateCount(serverTrust)
        for i in 0..<certCount {
            guard let cert = SecTrustGetCertificateAtIndex(serverTrust, i) else { continue }
            let certData = SecCertificateCopyData(cert) as Data
            let hash = sha256(certData)
            let hashB64 = Data(hash).base64EncodedString()
            if pinnedHashes.contains(hashB64) {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }

        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}

private func sha256(_ data: Data) -> Data {
    Data(SHA256.hash(data: data))
}
