//
// Created by Dave Carlton on 7/27/18.
// Copyright (c) 2018 Polymicro Systems. All rights reserved.
//

import Foundation
import Log

enum UpdateFrequency: Int {
    case daily = 1, weekly = 7, monthly = 30
}


let kUpdateFrequencyDefaultsKey  = "updateFrequency"
let kLogLevel = "logLevel"

class UserDefaultsManager {

    static let shared = UserDefaultsManager()

    var updateFrequency: UpdateFrequency? {
        get {
            guard let updateFrequency = UserDefaults.standard.value(forKey: kUpdateFrequencyDefaultsKey) as? Int else {
                return nil
            }
            return UpdateFrequency(rawValue: updateFrequency)
        }
        set(updateFrequency) {
            UserDefaults.standard.set(updateFrequency?.rawValue, forKey: kUpdateFrequencyDefaultsKey)
        }
    }

    func defaultsURL(filename: String) -> URL? {
        let error: Error? = nil
        let fileManager   = FileManager()
        // Saved appReflectors are in the Application Support folder
        let dir:   URL?   = try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        if error != nil {
            if let anError = error {
                HLog().error("Error finding app support directory \( anError )")
            }
        }
        // folder = reference to Application Support
        let folder              = URL(fileURLWithPath: dir?.path ?? "", isDirectory: true)
        let appSupportFolderURL = folder.appendingPathComponent(kHamsterAppSupport, isDirectory: true)
        let hamsterDefaultsURL  = appSupportFolderURL.appendingPathComponent(filename)
        if !FileManager.default.fileExists(atPath: appSupportFolderURL.path) {
            do {
                try FileManager.default.createDirectory(at: appSupportFolderURL, withIntermediateDirectories: false, attributes: nil)
            } catch {
                HLog().warning("Could not create Application Support folder for Hamster")
            }
        }
        return hamsterDefaultsURL
    }

    func saveToFile(url: URL, using: () ) {
            HLog().info("Saving: ", url.lastPathComponent)
            NotificationCenter.default.post(name: NSNotification.Name(kConnectionsAreReady), object: self)
    }

}
