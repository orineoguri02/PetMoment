import AVFoundation

extension AVAssetExportSession {
    func exportAsynchronously() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.exportAsynchronously {
                if let error = self.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
