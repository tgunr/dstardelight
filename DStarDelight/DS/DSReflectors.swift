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
import Log

let SOURCE_HEADER:           String = "# Prepared at ar-dns.net - "
let kHamster:                String = "Hamster"
let kHamsterAppSupport:      String = kHamster
let kHamsterReflectors:      String = "Reflectors.plist"
let kHamsterConnections:     String = "Connections.plist"
let kReflectorsAreReady:     String = "reflectorsAreReady"
let kReflectorSourceIsReady: String = "reflectorSourceIsReady"
let kNewReflectorFound:      String = "newReflectorFound"
let kReflectorSources:       String = "reflectorSources"
let kReflectorGateways:      String = "reflectorGateways"
let kConnectionsAreReady:    String = "connectionsAreReady"

class DSReflectors: NSObject {
    var reflectorSources: [ DSReflectorSource ] = []
    var gateways:         [ DSReflector ]       = []
    var actives: [ DSReflector ] {
        get {
            return gateways.filter {
                $0.active
            }
        }
    }
    var lastTask:           URLSessionDataTask?
    var defaultSourcesFile: URL?

    func defaultSourcesURL() -> URL? {
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
        let folder               = URL(fileURLWithPath: dir?.path ?? "", isDirectory: true)
        let appSupportFolderURL  = folder.appendingPathComponent(kHamsterAppSupport, isDirectory: true)
        let hamsterReflectorsURL = appSupportFolderURL.appendingPathComponent(kHamsterReflectors)
        if !FileManager.default.fileExists(atPath: appSupportFolderURL.path) {
            do {
                try FileManager.default.createDirectory(at: appSupportFolderURL, withIntermediateDirectories: false, attributes: nil)
            } catch {
                HLog().warning("Could not create Application Support folder for Hamster")
            }
        }
        return hamsterReflectorsURL
    }

    override
    init() {
        super.init()
        defaultSourcesFile = defaultSourcesURL()
    }

    required
    init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        do {
            try gateways = aDecoder.decodeObject(forKey: kReflectorGateways) as! [ DSReflector ]
            try reflectorSources = aDecoder.decodeObject(forKey: kReflectorSources) as! [ DSReflectorSource ]
            HLog().debug("DECODED")
        } catch {
            HLog().error("DECODE FAILED")
        }
        defaultSourcesFile = defaultSourcesURL()
    }

    override
    func encode(with aCoder: NSCoder) {
        HLog().trace("Encoder")
        aCoder.encode(gateways, forKey: kReflectorGateways)
        aCoder.encode(reflectorSources, forKey: kReflectorSources)
        super.encode(with: aCoder)
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
            let reflectorSourceDefaults: [ String ]?
                    = UserDefaults.standard.object(forKey: kReflectorSources) as? [ String ]
            var lastReflectorSource:     DSReflectorSource?
            self.reflectorSources = []
            // build list of default sources
            for theSource in reflectorSourceDefaults! as [ String ] {
                let reflectorSource: DSReflectorSource = DSReflectorSource(urlString: theSource)
                var session                            = URLSession.shared
                var request                            = URLRequest.init(url: reflectorSource.sourceURL!)
                request.httpMethod = "HEAD"
                self.lastTask = session.dataTask(with: request, completionHandler: { data, response, error in
                    // handle response
                    if error != nil {
                        if let aKey = ( error as NSError? )?.userInfo[ NSURLErrorFailingURLStringErrorKey ] {
                            HLog().error("reflectorSource connection failed! Error - \( error?.localizedDescription ?? "" ) \( aKey )\n\n")
                        }
                    } else {
                        self.updateReflectorsForSource(reflectorSource)
                        HLog().debug("reflectorSource loaded: \( reflectorSource.sourceURL?.path )")
                    }
                })
                lastReflectorSource = reflectorSource
                self.lastTask?.resume()
            }
            lastReflectorSource?.isLast = true
            HLog().debug("last: ", lastReflectorSource?.name ?? "NONE")
        })
    }

    func loadDefaultSources() {
        HLog().info()
        asyncLoadFromFile()
    }

    func reloadReflectors() {
        self.gateways = []
        checkForOutDated()
    }

    func checkForOutDated() {
        let reflectorsUpdated: Date?  = UserDefaults.standard.object(forKey: "reflectorsUpdated") as? Date
        let since:             Double = TimeInterval(fabs(Float(reflectorsUpdated?.timeIntervalSinceNow ?? 0.0)))
        let numGateways:       Int    = gateways.count
        let days:              Int?   = UserDefaultsManager.shared.updateFrequency?.rawValue
        let expired:           Double = TimeInterval(days! * 24 * 60 * 60)
        let nextUpdate:        Date   = reflectorsUpdated! + expired
        HLog().debug("Last update: \( String(describing: reflectorsUpdated) ) nextUpdate: \( nextUpdate )")
        if ( since > expired ) || ( numGateways == 0 ) {
            HLog().info("Sources are outdated, updating now")
            update()
        }
        saveReflectorsToFile()
    }

    func updateReflectorsForSource(_ reflectorSource: DSReflectorSource) {
        HLog().debug("reflectorSource \( String(describing: reflectorSource.sourceURL?.description) )")
        let aSourceURL:    URL?    = reflectorSource.sourceURL
        var lineSet                = CharacterSet.newlines
        var sourceContent: String? = nil
        do {
            sourceContent = try String(contentsOf: aSourceURL!)
        } catch {
            HLog().error("Error loading sources from", aSourceURL?.path ?? "PATH?")
            return
        }
        let contentLines = sourceContent?.components(separatedBy: lineSet)
        let first        = contentLines?.first
        if first?.hasPrefix(SOURCE_HEADER) ?? false {
            let headerLength: Int = SOURCE_HEADER.count
            let headerDateString  = ( first as NSString? )?.substring(from: headerLength)
            let dateFormatter     = DateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US") as Locale
            // TODO: Fix this date problem
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            let date: Date? = dateFormatter.date(from: headerDateString ?? "")
            if let aDate = date {
                HLog().info("Date: \( aDate )")
            }
            reflectorSource.lastUpdate = date
            lineSet = CharacterSet.whitespaces
            var reflectorList: [ String: DSReflector ] = [:]
            for aLine in contentLines ?? [String?]() {
                let lineItems = aLine?.components(separatedBy: lineSet)
                if lineItems?.count == 2 {
                    let aReflector: DSReflector? = DSReflector()
                    aReflector?.name = ( lineItems?[ 0 ] )!
                    aReflector?.ip = ( lineItems?[ 1 ] )!
                    if reflectorList[ ( aReflector?.name )! ] == nil {
                        reflectorList[ ( aReflector?.name )! ] = aReflector
                        gateways.append(aReflector!)
                        NotificationCenter.default.post(name: NSNotification.Name("newReflectorFound"), object: aReflector)
                    } else {
                        HLog().warning("Duplicate reflector: ", aReflector?.name)
                    }
                }
                if HLog().minLevel < LogLevel.info {
                    if reflectorList.count > 2 {
                        HLog().debug(reflectorSource.name, ": truncated")
                        break
                    }
                }
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(kReflectorSourceIsReady), object: reflectorSource)
    }

    func update() {
        // update reflector lists
        HLog().debug("")
        gateways = []
        for reflectorSource in reflectorSources {
            updateReflectorsForSource(reflectorSource)
        }
    }

    private
    func setReflectorsAreUpdated() {
        let today = Date()
        UserDefaults.standard.set(today, forKey: "reflectorsUpdated")
        HLog().debug("set update: \( today )")
    }

    func saveReflectorsToFile() {
        if ( self.reflectorSources.count != 0 ) && ( self.gateways.count != 0 ) {
            HLog().info("Saving reflectors")
            self.write(toFile: ( defaultSourcesURL()?.path )!, atomically: false)
            NotificationCenter.default.post(name: NSNotification.Name(kReflectorsAreReady), object: self)
        } else {
            HLog().error("Saving reflectors failed!")
            HLog().error("reflectorSources count: &d gateways count: %d",
                         self.reflectorSources.count, self.gateways.count)
        }
    }

    func loadSavedReflectors() -> DSReflectors? {
        var reflectorList: DSReflectors?
        // See if we have a saved list
        reflectorList = DSReflectors(contentsOfFile: defaultSourcesFile!.path)
        if reflectorList == nil {
            HLog().error("Error loading saved reflectors")
            return nil
        }
        if ( reflectorList == nil ) ||
                   ( reflectorList?.gateways == nil ) ||
                   ( reflectorList?.gateways.count == 0 ) ||
                   ( reflectorList?.reflectorSources.count == 0 ) {
            // no list
            NotificationCenter.default.addObserver(self, selector: #selector(self.reflectorSourceIsReady(_:)), name: NSNotification.Name(kReflectorSourceIsReady), object: nil)
            HLog().info("No local reflectorlist, Waiting for \( kReflectorsAreReady )")
            loadDefaultSources()
        } else {
            // we have a list, check if outdated
            HLog().info("Local reflectorList found")
            reflectorList?.checkForOutDated()
        }
        return reflectorList
    }

    // MARK: Access
    func reflectorGateways() -> [ DSReflector ]? {
        return gateways
    }

    func reflectorsActive() -> [ DSReflector ]? {
        return reflectorGateways()?.filter {
            $0.active
        }
    }
}
