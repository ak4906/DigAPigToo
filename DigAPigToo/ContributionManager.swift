//
//  ContributionManager.swift
//  DigAPigToo
//
//  Handles uploading user-contributed photos to CloudKit's public database.
//  Records land in the "Contribution" record type in iCloud.cometzfly.DigAPigToo.
//  Browse submissions at: https://icloud.developer.apple.com → CloudKit Console → Data
//

import CloudKit
import UIKit

@MainActor
class ContributionManager: ObservableObject {

    enum State: Equatable {
        case idle
        case uploading
        case success
        case failure(String)
    }

    @Published var state: State = .idle

    private let db = CKContainer(identifier: "iCloud.cometzfly.DigAPigToo").publicCloudDatabase

    // MARK: - Submit

    func submit(structureName: String, image: UIImage, notes: String) {
        guard state != .uploading else { return }
        state = .uploading

        Task {
            do {
                let record = CKRecord(recordType: "Contribution")
                record["structureName"] = structureName as CKRecordValue
                record["notes"]         = notes as CKRecordValue
                record["timestamp"]     = Date() as CKRecordValue

                // Write compressed JPEG to a temp file so CKAsset can reference it
                guard let jpeg = image.jpegData(compressionQuality: 0.82) else {
                    throw ContributionError.imageProcessingFailed
                }
                let tmpURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + ".jpg")
                try jpeg.write(to: tmpURL)
                record["photo"] = CKAsset(fileURL: tmpURL)

                _ = try await db.save(record)

                try? FileManager.default.removeItem(at: tmpURL)
                state = .success

            } catch let ckError as CKError {
                state = .failure(ckError.localizedDescription)
            } catch ContributionError.imageProcessingFailed {
                state = .failure("Couldn't process the image. Try a different photo.")
            } catch {
                state = .failure(error.localizedDescription)
            }
        }
    }

    func reset() { state = .idle }
}

// MARK: - Errors

private enum ContributionError: Error {
    case imageProcessingFailed
}
