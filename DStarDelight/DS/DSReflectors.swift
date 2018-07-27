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

let SOURCE_HEADER = "# Prepared at ar-dns.net - "
let HAMSTER_APPSUPPORT = "Hamster"
let HAMSTER_REFLECTORS = HAMSTER_APPSUPPORT + "Reflectors.plist"

func urlReflectors() -> URL? {
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

    override init() {
        super.init()

        let reflectorsURL = urlReflectors()
        // See if we have a saved list
        let reflectorList: DSReflectors = DSReflectors(contentsOfFile: urlReflectors()!.path)!
        if (reflectorList == nil) || (reflectorList.reflectorGateways == nil) || (reflectorList.reflectorGateways.count == 0) {
            // no list, so create one and save it
            // Do this async as it takes a few seconds to gather the data
            NotificationCenter.default.addObserver(self, selector: #selector(self.reflectorSourceIsReady(_:)), name: NSNotification.Name("reflectorSourceIsReady"), object: nil)
            HLog().info("Waiting for reflectorSourceIsReady")
            loadDefaultSources(reflectorsURL)
        } else {
            HLog().info("Local reflectorList found")
            checkForOutDated()
            NotificationCenter.default.post(name: NSNotification.Name("reflectorsAreReady"), object: reflectorList)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        HLog().debug("Decoder")
        super.init(coder: aDecoder)
//            NotificationCenter.default.post(name: NSNotification.Name("reflectorsAreReady"), object: reflectorList)
    }

    override func encode(with aCoder: NSCoder) {
        HLog().debug("Encoder")
        NSObjectCoder.encodeProperties(of: self, to: aCoder)
    }

    @objc

    func reflectorSourceIsReady(_ notification: Notification?) {
        let reflectorSource = notification?.object as! DSReflectorSource
        updateReflectorsForSource(reflectorSource)
        self.reflectorSources.append(reflectorSource)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("reflectorSourceIsReady"), object: nil)
        HLog().debug("DSReflectors: reflectorSourceIsReady: %d", reflectorSources.count)
    }

    // checkOutOfDate looks for the default list of sources in the preferences
    // then pings them to see if alive. If alive, the source is added to the list for sources.
    func asyncLoad(_ url: URL?, usingBlock block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: {
            HLog().debug("DSReflectors: asyncLoad")
            let reflectorSourceDefaults: [String]? = UserDefaults.standard.object(forKey: "reflectorSources") as? [String]
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
                            HLog().error("Connection failed! Error - \(error?.localizedDescription ?? "") \(aKey)\n\n")
                        }
                    } else {
                        reflectorSource.active = true
                        self.reflectorSources.append(reflectorSource)
                        HLog().debug("Finished Request")
                    }
                })
                self.lastTask?.resume()
            }
            // execute block on list of sources
            block()
        })
    }

    func loadDefaultSources(_ url: URL?) {
        HLog().info()
        let reflectorSourceDefaults: [String]? = UserDefaults.standard.object(forKey: "reflectorSources") as? [String]
        // build list of default sources
        var lastReflectorSource: DSReflectorSource?

        for theSource in reflectorSourceDefaults! as [String] {
            let reflectorSource: DSReflectorSource = DSReflectorSource(urlString: theSource)
            updateReflectorsForSource(reflectorSource)
            self.reflectorSources.append(reflectorSource)
            lastReflectorSource = reflectorSource
        }
        lastReflectorSource?.isLast = true
        HLog().info("Saving reflectors")
        self.write(toFile: (urlReflectors()?.path)!, atomically: false)
        NotificationCenter.default.post(name: NSNotification.Name("reflectorsAreReady"), object: self)
    }

    func loadReflectors(_ url: URL?) {
        asyncLoad(url, usingBlock: {
            HLog().debug("DSReflectors: loadReflectors")
            self.checkForOutDated()
//            self.reflectorGateways = NSKeyedUnarchiver.unarchiveObject(withFile: (url?.path)!) as! [DSReflector]
            NotificationCenter.default.post(name: NSNotification.Name("reflectorsAreReady"), object: self)
        })
    }

    func reload() {
        let reflectorsURL = urlReflectors()
        asyncLoad(reflectorsURL, usingBlock: {
            self.update()
//            self.write(toFile: urlReflectors?.path ?? "", atomically: true)
            NotificationCenter.default.post(name: NSNotification.Name("reflectorsAreReady"), object: self)
        })
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
//        if reflectorSource.isLast == true {
//            NotificationCenter.default.post(name: NSNotification.Name("reflectorsAreReady"), object: self)
    }

    func update() {
        // update reflector lists
        for reflectorSource in reflectorSources {
            updateReflectorsForSource(reflectorSource)
        }
        setReflectorsAreUpdated()
    }

    private func setReflectorsAreUpdated() {
        let today = Date()
        UserDefaults.standard.set(today, forKey: "reflectorsUpdated")
        HLog().debug("set update: \(today)")
    }
}
