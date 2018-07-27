//  Converted to Swift 4 by Swiftify v4.1.6766 - https://objectivec2swift.com/
//
//  DSReflectors.m
//  DStarDelight
//
//  Created by Dave Carlton on 7/13/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import NSObjectCoder
import AutoCoding

let SOURCE_HEADER          = "# Prepared at ar-dns.net - "
let HAMSTER_APPSUPPORT     = "Hamster"
let HAMSTER_REFLECTORS     = HAMSTER_APPSUPPORT + "Reflectors.plist"
let REFLECTORS_READY       = "reflectorsAreReady"
let REFLECTOR_SOURCE_READY = "reflectorSourceIsReady"
let NEW_REFLECTOR_FOUND = "newReflectorFound"

func defaultSourcesURL() -> URL? {
    let error: Error? = nil
    let fileManager = FileManager()
    // Saved appReflectors are in the Application Support folder
    let dir: URL? = try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    if error != nil {
        if let anError = error {
            HLog().error("Error finding app support directory \(anError)")
        }
    }
    // folder = reference to Application Support
    let folder = URL(fileURLWithPath: dir?.path ?? "", isDirectory: true)
    let appSupportFolderURL = folder.appendingPathComponent(HAMSTER_APPSUPPORT, isDirectory: true)
    let hamsterReflectorsURL = appSupportFolderURL.appendingPathComponent(HAMSTER_REFLECTORS)
    if !FileManager.default.fileExists(atPath: appSupportFolderURL.path) {
        do {
            try FileManager.default.createDirectory(at: appSupportFolderURL, withIntermediateDirectories: false, attributes: nil)
        } catch {
            HLog().warning("Could not create Application Support folder for Hamster")
        }
    }
    return hamsterReflectorsURL
}

class DSReflectors: NSObject {
    var reflectorSources: [DSReflectorSource] = []
    var reflectorGateways: [DSReflector] = []
    var lastTask: URLSessionDataTask?
    let defaultSourcesFile: URL?

    override init() {
        defaultSourcesFile = defaultSourcesURL()
        super.init()

        // See if we have a saved list
        let reflectorList: DSReflectors = DSReflectors(contentsOfFile: defaultSourcesFile!.path)!
        if (reflectorList == nil) || (reflectorList.reflectorGateways == nil) || (reflectorList.reflectorGateways.count == 0) {
            // no list
            NotificationCenter.default.addObserver(self, selector: #selector(self.reflectorSourceIsReady(_:)), name: NSNotification.Name(REFLECTOR_SOURCE_READY), object: nil)
            HLog().info("No local reflectorlist, Waiting for \( REFLECTORS_READY )")
            loadDefaultSources()
        } else {
            // we have a list, check if outdated
            HLog().info("Local reflectorList found")
            checkForOutDated()
            NotificationCenter.default.post(name: NSNotification.Name(REFLECTORS_READY), object: reflectorList)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        HLog().debug("Decoder")
        defaultSourcesFile = defaultSourcesURL()
        super.init(coder: aDecoder)
    }

    override func encode(with aCoder: NSCoder) {
        HLog().debug("Encoder")
        NSObjectCoder.encodeProperties(of: self, to: aCoder)
    }

    @objc
    func reflectorSourceIsReady(_ notification: Notification?) {
    // Called by notification from updateReflectorsForSource after each source has been updated
        let reflectorSource: DSReflectorSource = notification?.object as! DSReflectorSource
        self.reflectorSources.append(reflectorSource)
        if reflectorSource.isLast == true {
            // Last reflector is finished, save and notify the reflectors are ready
            saveReflectorsToFile()
            setReflectorsAreUpdated()
        }
        HLog().debug("count: ", reflectorSources.count, "last: ", reflectorSource.isLast)
    }

    // Look for the default list of sources in the preferences
    // then pings them to see if alive. If alive, the source is added to the list for sources.
    func asyncLoadFromFile() {
        DispatchQueue.main.async(execute: {
            HLog().debug("")
            let reflectorSourceDefaults: [String]? = UserDefaults.standard.object(forKey: "reflectorSources") as? [String]
            var lastReflectorSource: DSReflectorSource?
            self.reflectorSources = []
            // build list of default sources
            for theSource in reflectorSourceDefaults! as [String] {
                let reflectorSource: DSReflectorSource = DSReflectorSource(urlString: theSource)
                var session = URLSession.shared
                var request = URLRequest.init(url: reflectorSource.sourceURL!)
                request.httpMethod = "HEAD"
                self.lastTask = session.dataTask(with: request, completionHandler: { data, response, error in
                    // handle response
                    if error != nil {
                        if let aKey = (error as NSError?)?.userInfo[NSURLErrorFailingURLStringErrorKey] {
                            HLog().error("reflectorSource connection failed! Error - \(error?.localizedDescription ?? "") \(aKey)\n\n")
                        }
                    } else {
                        self.updateReflectorsForSource(reflectorSource)
                        HLog().debug("reflectorSource loaded: \(reflectorSource.sourceURL?.path)")
                    }
                })
                lastReflectorSource = reflectorSource
                self.lastTask?.resume()
            }
            lastReflectorSource?.isLast = true
            HLog().debug("last: ", lastReflectorSource?.name)
        })
    }

    func loadDefaultSources() {
        HLog().info()
        asyncLoadFromFile()
    }

    func reloadReflectors() {
        self.reflectorGateways = []
        loadDefaultSources()
    }

    func checkForOutDated() {
        let reflectorsUpdated = UserDefaults.standard.object(forKey: "reflectorsUpdated") as? Date
        let since = TimeInterval(fabs(Float(reflectorsUpdated?.timeIntervalSinceNow ?? 0.0)))
        let numGateways = reflectorGateways.count
        HLog().debug("Last update: \(reflectorsUpdated) since: \(since)")
        // TODO: Check monthly while debugging
        if (since > (30 * 24 * 60 * 60)) || (numGateways == 0) {
            update()
        }
    }

    func updateReflectorsForSource(_ reflectorSource: DSReflectorSource) {
        HLog().debug("reflectorSource \(reflectorSource.sourceURL?.description)")
        let aSourceURL: URL? = reflectorSource.sourceURL
        var error: Error?
        var encoded: String.Encoding
        var lineSet = CharacterSet.newlines
        var sourceContent: String? = nil
        do {
            sourceContent = try String(contentsOf: aSourceURL!)
        } catch {
            HLog().info("DSReflectors: update: Error loading sources from %@", aSourceURL)
            return
        }
        let contentLines = sourceContent?.components(separatedBy: lineSet)
        let first = contentLines?.first
        if first?.hasPrefix(SOURCE_HEADER) ?? false {
            let headerLength: Int = SOURCE_HEADER.count
            let headerDateString = (first as? NSString)?.substring(from: headerLength)
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US") as Locale
            // TODO: Fix this date problem
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            let date: Date? = dateFormatter.date(from: headerDateString ?? "")
            if let aDate = date {
                HLog().info("Date: \(aDate)")
            }
            reflectorSource.lastUpdate = date
            lineSet = CharacterSet.whitespaces
            var reflectorList: [String: DSReflector] = [:]
            for aLine in contentLines ?? [String?]() {
                let lineItems = aLine?.components(separatedBy: lineSet)
                if lineItems?.count == 2 {
                    let aCoder = NSCoder()
                    let aReflector: DSReflector? = DSReflector()
                    aReflector?.name = (lineItems?[0])!
                    aReflector?.ip = (lineItems?[1])!
                    if reflectorList[(aReflector?.name)!] == nil {
                        reflectorList[(aReflector?.name)!] = aReflector
                        reflectorGateways.append(aReflector!)
                        NotificationCenter.default.post(name: NSNotification.Name("newReflectorFound"), object: aReflector)
                    } else {
                        HLog().warning("Duplicate reflector: \(aReflector?.name)")
                    }
                }
                // TODO: Debug code
                if reflectorList.count > 2 {
                    break
                }
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(REFLECTOR_SOURCE_READY), object: reflectorSource)
    }

    func update() {
        // update reflector lists
        reflectorGateways = []
        for reflectorSource in reflectorSources {
            updateReflectorsForSource(reflectorSource)
        }
    }

    private func setReflectorsAreUpdated() {
        let today = Date()
        UserDefaults.standard.set(today, forKey: "reflectorsUpdated")
        HLog().debug("set update: \(today)")
    }

    func saveReflectorsToFile() {
        if (self.reflectorSources.count != 0) && (self.reflectorGateways.count != 0) {
            HLog().info("Saving reflectors")
            self.write(toFile: (defaultSourcesURL()?.path)!, atomically: false)
            NotificationCenter.default.post(name: NSNotification.Name(REFLECTORS_READY), object: self)
        } else {
            HLog().error("Saving reflectors failed!")
            HLog().error("reflectorSources count: &d reflectorGateways count: %d",
                         self.reflectorSources.count, self.reflectorGateways.count)
        }
    }

}
