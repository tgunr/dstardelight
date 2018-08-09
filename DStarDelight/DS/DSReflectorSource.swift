//  Converted to Swift 4 by Swiftify v4.1.6766 - https://objectivec2swift.com/
//
// Created by Dave Carlton on 7/13/18.
// Copyright (c) 2018 Polymicro Systems. All rights reserved.
//

import Foundation

class DSReflectorSource: DSReflector {
    var sourceURL: URL?
    var lastResponse: URLResponse?
    var lastTask: URLSessionDataTask?
    var isLast: Bool = false
    var lastUpdate: Date?
    var decscription: String {
        return (sourceURL?.path)!
    }

    override init() {
        super.init()
    }

    init(urlString: String) {
        super.init()
        sourceURL = URL(string: urlString)

        if sourceURL?.scheme == nil {
            sourceURL = URL(string: "http://" + urlString)
        }
        name = urlString
        testURL()
    }

    required init?(coder aDecoder: NSCoder) {
//        HLog().debug("")

        super.init(coder: aDecoder)

        self.sourceURL = nil
        self.lastResponse = nil
        self.lastUpdate = nil

        if let archivedURL: URL = aDecoder.decodeObject(forKey: "reflectorURL") as? URL {
            self.sourceURL = archivedURL
        }

        if let archiveResponse: URLResponse = aDecoder.decodeObject(forKey: "reflectorResponse") as? URLResponse {
            self.lastResponse = archiveResponse
        }

        if aDecoder.containsValue(forKey: "reflectorLastUpdate") {
            self.active = ( aDecoder.decodeObject(forKey: "reflectorLastUpdate") != nil )
        }

    }


    override func encode(with aCoder: NSCoder) {
//        HLog().debug("")
        aCoder.encode(sourceURL, forKey: "reflectorURL")
        aCoder.encode(lastUpdate, forKey: "reflectorLastUpdate")
        super.encode(with: aCoder)
    }

    func testURL() {
//        var error: Error?
//        var response: HTTPURLResponse?
        var headRequest = NSMutableURLRequest(url: sourceURL!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30.0)
        headRequest.httpMethod = "HEAD"
        HLog().info("Testing: \(sourceURL?.description ?? "NO URL")")

//        if NSURLConnection.canHandle(headRequest as URLRequest) {
//            do {
//                try NSURLConnection.sendSynchronousRequest(headRequest as URLRequest, returning: response as? AutoreleasingUnsafeMutablePointer<URLResponse?>)
//            } catch {
//                HLog().info("HEAD request failed: %s", sourceURL?.absoluteString)
//            }
//        }
        let session = URLSession.shared
        if let aString = URL(string: (sourceURL?.absoluteString)!) {
            (session.dataTask(with: aString, completionHandler: { data, response, error in
                // handle response
                if error != nil {
                    if let aKey: Any = (error! as NSError).userInfo[NSURLErrorFailingURLStringErrorKey] {
                        HLog().error("Connection failed! Error:%s Key:%s", error?.localizedDescription ?? "", aKey)
                    }
                } else {
                    self.active = (response as! HTTPURLResponse).statusCode == 200
                    HLog().debug("active: \(self.active)")
                }
            })).resume()
        }
    }
}
