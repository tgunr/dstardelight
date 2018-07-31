import MapKit

//import DispatchFramework

#if os(OSX)
import AppKit
import Cocoa
typealias ColorType = NSColor
typealias ImageType = NSImage
#elseif os(iOS)
import UIKit
typealias ColorType = UIColor
typealias ImageType = UIImage
#endif

struct StreamInfo {
    var rpt1Call: String = ""
    var rpt2Call: String = ""
    var myCall: String = ""
    var myCall2: String = ""
    var urCall: String = ""
    var streamId: Int = 0
    var time: Date = Date()
    var message: String = ""
    var compositeMyCall: String = ""
    var direction: String = ""
    var color: ColorType = ColorType.black
    
    func asDictionary() -> [ String : Any? ] {
        let dictionary: [ String : Any? ] = [
            "rpt1Call": rpt1Call,
            "rpt2Call": rpt2Call,
            "myCall": myCall,
            "myCall2": myCall2,
            "urCall": urCall,
            "streamID": streamId,
            "time": time,
            "message": message,
            "direction": direction,
            "color": color]
        return dictionary
    }
    
    func asHashableDictionary() -> [ AnyHashable: Any ] {
        let hashable = self.asDictionary() as [ AnyHashable: Any ]
        return hashable
    }
    
    mutating func fromDictionary(_ dictionary: [ String : Any? ]) {
        rpt1Call = dictionary["rpt1Call"] as? String ?? ""
        rpt2Call = dictionary["rpt2Call"] as? String ?? ""
        myCall = dictionary["myCall"] as? String ?? ""
        myCall2 = dictionary["myCall2"] as? String ?? ""
        urCall = dictionary["urCall"] as? String ?? ""
        streamId = dictionary["streamID"] as? Int ?? 0
        time = dictionary["time"] as? Date ?? Date()
        message = dictionary["message"] as? String ?? ""
        direction = dictionary["direction"] as? String ?? ""
        color = dictionary["color"] as? ColorType ?? ColorType.black
    }
}

class HQSOCQViewController: NSViewController {
    private var qsoTimer: DispatchSource?
    private var txButtonState: Int = 0
    private var speechSynth: NSSpeechSynthesizer?
    private var geocoder: CLGeocoder?
    private var mapPopover: NSPopover?
    private var addPopover: NSPopover?
    private var qsoList: [ [AnyHashable : Any] ]  = [ [ : ] ]
//    var txKeyCode: MASShortcut?

    var reflectors: DSReflectors?
    let appDelegate = NSApplication.shared.delegate as! HAppDelegate

    @IBOutlet var heardArrayController: NSArrayController!
    @IBOutlet var heardTableController: NSArrayController!
    @IBOutlet weak var heardTableView: NSTableView!
    @IBOutlet var connectionTableView: NSTableView!
    @IBOutlet weak var statusLED: NSImageView!

    @IBOutlet var transmitButton: NSButton!
    @IBOutlet weak var repeaterInfo: NSTextField!

    @IBOutlet var volumeSlider: NSSlider!
    @IBOutlet weak var reflectorPopup: NSPopUpButton!

    @IBOutlet var connectReflector: NSButton!
    @IBOutlet var reflectorsTabViewItem: NSTabViewItem!
    
    // MARK: - Methods
    class func findQsoId(_ streamId: Int?, inArray array: [Any]?) -> Int {
        return (array as NSArray?)?.indexOfObject(passingTest: { obj, idx, stop in
            let entry = obj as? [AnyHashable : Any]
            if streamId != nil && ((entry?["streamId"] as? Int) == streamId) {
                stop.pointee = true
                return true
            }
            return false
        }) ?? 0
    }

     override func viewDidLoad() {
        reflectors = appDelegate.appReflectors
//        reflectorGateways = reflectors?.reflectorGateways
    }

    func reflectorsAreReady() {
    }

    func updateQsoId(_ streamId: Int?, usingBlock block: @escaping ([AnyHashable : Any], Int) -> Void) -> Bool {
        let qsoIndex: Int = HQSOCQViewController.findQsoId(streamId, inArray: qsoList)
        if qsoIndex == NSNotFound {
            return false
        }
        let qso = qsoList[qsoIndex]
        block(qso, qsoIndex)
        return true
    }

    // XXX These probably shouldn't be called "headers" anymore.  They're really stream info dictionaries.
    func streamDidStart(_ inHeader: [String : Any?]) {
        
        var streamInfo = StreamInfo()
        streamInfo.fromDictionary(inHeader)
        
        var sInfo: [ String : Any? ] = [ : ]
        sInfo["rpt1Call"]          = inHeader["rpt1Call"]        as? String ?? ""
        sInfo["rpt2Call"]          = inHeader["rpt2Call"]        as? String ?? ""
        sInfo["myCall"]            = inHeader["myCall"]          // as? String ?? ""
        sInfo["myCall2"]           = inHeader["myCall2"]         as? String ?? ""
        sInfo["urCall"]            = inHeader["urCall"]          as? String ?? ""
        sInfo["streamId"]          = inHeader["streamId"]        as? Int    ?? 0
        sInfo["time"]              = inHeader["time"]            as? Date   ?? Date()
        sInfo["message"]           = inHeader["message"]         as? String ?? ""
        sInfo["compositeMyCall"]   = inHeader["compositeMyCall"] as? String ?? ""
        sInfo["direction"]         = inHeader["direction"]       as? String ?? ""
        sInfo["color"]             = inHeader["color"]           as? ColorType ?? ColorType.black
        
        var rpt1Call: String = sInfo["rpt1Call"] as! String
        var rpt2Call: String = sInfo["rpt2Call"] as! String
        let myCall: String = sInfo["myCall"] as! String
        let myCall2: String = sInfo["myCall2"] as! String
        let urCall: String = sInfo["urCall"] as! String
        let streamId: Int = sInfo["streamId"] as! Int
        let time: Date = sInfo["time"] as! Date
        var message: String = sInfo["message"] as! String
        var compositeMyCall: String = sInfo["compositeMyCall"] as! String
        let direction: String = sInfo["direction"] as! String
        var color: ColorType = sInfo["color"] as! ColorType
        
        if (streamInfo.myCall == "") {
            streamInfo.compositeMyCall = myCall
        } else {
            streamInfo.rpt1Call = streamInfo.rpt1Call.trimmingCharacters(in: CharacterSet.whitespaces)
            streamInfo.rpt2Call = streamInfo.rpt2Call.trimmingCharacters(in: CharacterSet.whitespaces)
            streamInfo.compositeMyCall = "\(rpt1Call)/\(rpt2Call)"
        }
        
        if (streamInfo.direction == "TX") {
            streamInfo.color = ColorType.red
            streamInfo.message = UserDefaults.standard.string(forKey: "slowDataMessage") ?? ""
            statusLED.image = ImageType(named: ImageType.Name("Red"))
        } else {
            streamInfo.color = ColorType(calibratedRed: 0.088, green: 0.373, blue: 0.139, alpha: 1.000)
            statusLED.image = ImageType(named: ImageType.Name("Green"))
        }
        
        var updated = updateQsoId(streamInfo.streamId, usingBlock: { qso, qsoIndex in })
        if (updated == false) {
            if mapPopover?.isShown != nil {
//                (mapPopover?.contentViewController as? DSMapPopupController)?.suppressClose = true
            }
            
            qsoList.append(streamInfo.asHashableDictionary())
            heardTableController.rearrangeObjects()
            weak var weakSelf: HQSOCQViewController? = self
            var dTime = (100 * NSEC_PER_MSEC)
               dTime += (100 * NSEC_PER_MSEC) + 10 * NSEC_PER_MSEC
            let interval = TimeInterval.init(exactly: 0.01)
//            Dispatch.after(interval!) {
//                var _ = (weakSelf?.updateQsoId(streamInfo.streamId, usingBlock: { qso, qsoIndex in
//                    var aQso = qso["time"] as? Date
//                    if aQso != nil {
//                        qso["duration"] = Date().timeIntervalSince(aQso)
//                    }
//                }))
//            qsoTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, DispatchQueue.main)
//            dispatch_source_set_timer(qsoTimer, DispatchTime.now() + Double(100 * NSEC_PER_MSEC), 100 * NSEC_PER_MSEC, 10 * NSEC_PER_MSEC)
//            dispatch_source_set_event_handler(qsoTimer, {
//                weakSelf?.updateQsoId(streamId as? NSNumber, usingBlock: { qso, qsoIndex in
//                    if let aQso = qso?["time"] as? Date {
//                        qso?["duration"] = Date().timeIntervalSince(aQso)
//                    }
//                })
//            })
//            qsoTimer.resume()
            }
    }

//    
//    func streamDidEnd(_ streamId: NSNumber?, atTime time: Date?) {
//        dispatch_source_cancel(qsoTimer)
//        updateQsoId(streamId, usingBlock: { qso, qsoIndex in
//            let headerTime: Date? = time
//            if let aQso = qso?["time"] as? Date {
//                qso?["duration"] = headerTime?.timeIntervalSince(aQso) ?? 0.0
//            }
//            if (qso?["direction"] == "TX") {
//                qso?["color"] = NSColor(calibratedRed: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
//            } else {
//                qso?["color"] = NSColor.black
//            }
//        })
//        let qsoIndex: Int = QSOCQViewController.findQsoId(streamId, inArray: heardTableController.arrangedObjects as? [Any])
//        //  If we can't find the QSO, it's probably not visible and we don't need to reset its color.
//        if qsoIndex != NSNotFound {
//            resetColor(for: heardTableView.rowView(atRow: qsoIndex, makeIfNecessary: false), atRow: qsoIndex)
//        }
//        statusLED.image = NSImage(named: NSImage.Name("Grey"))
//    }
//
//    func slowDataReceived(_ slowData: String?, forStreamId streamId: NSNumber?) {
//        updateQsoId(streamId, usingBlock: { qso, qsoIndex in
//            qso?["message"] = slowData ?? ""
//        })
//    }
//
//    func locationReceived(_ location: DSEAprsLocation?, forStreamId streamId: NSNumber?) {
//        assert(location != nil, "Invalid parameter not satisfying: location != nil")
//        updateQsoId(streamId, usingBlock: { qso, qsoIndex in
//            let oldLocation: CLLocation? = (qso?["location"] as? DSEAprsLocation)?.location
//            if let aLocation = location {
//                qso?["location"] = aLocation
//            }
//            if let aLocation = oldLocation {
//                if oldLocation != nil && (location?.location.distance(from: aLocation) ?? 0.0) < 100.0 {
//                    return
//                }
//            }
//            qso?["city"] = "Searching city database…"
//            if let aLocation = location?.location {
//                self.geocoder?.reverseGeocodeLocation(aLocation, completionHandler: { placemarks, error in
//                    if placemarks == nil {
//                        print("placemarks are nil")
//                        return
//                    }
//                    if error != nil {
//                        if let anError = error {
//                            print("Error returned from geocoder: \(anError)")
//                        }
//                        return
//                    }
//                    if placemarks?.count == 0 {
//                        print("No placemarks returned")
//                        return
//                    }
//                    //NSLog(@"Got %ld placemarks", placemarks.count);
//                    //NSLog(@"Got placemarks: %@", [NSString stringWithFormat:@"%@, %@, %@", placemarks[0].locality, placemarks[0].administrativeArea, placemarks[0].country]);
//                    self.updateQsoId(streamId, usingBlock: { innerQso, innerQsoIndex in
//                        innerQso?["city"] = "\(placemarks?[0].locality ?? ""), \(placemarks?[0].administrativeArea ?? ""), \(placemarks?[0].country ?? "")"
//                    })
//                    // qso[@"city"] = [NSString stringWithFormat:@"%@, %@, %@", placemarks[0].locality, placemarks[0].administrativeArea, placemarks[0].country];
//                })
//            }
//        })
//    }
//
//    func destinationDidConnect(_ destination: String?) {
//    }
//
//    func destinationDidError(_ destination: String?) throws {
//    }
//
//    func destinationDidLink(_ destination: String?) {
//    }
//
//    func destinationDidUnlink(_ destination: String?) {
//    }
//
//    func destinationWillLink(_ destination: String?) {
//    }
//
//    func viewDidLoad() {
//        super.viewDidLoad()
//        if let anInit = [AnyHashable]() as? [[AnyHashable : Any]] {
//            qsoList = anInit
//        }
//        mapPopover = NSPopover()
//        mapPopover?.contentViewController = DSMapPopupController(nibName: nil, bundle: nil)
//        mapPopover?.behavior = .transient
//        mapPopover?.delegate = mapPopover?.contentViewController as? DSMapPopupController
//        addPopover = NSPopover()
//        let addController = DSAddPopupController(nibName: nil, bundle: nil)
//        //    addController.reflectorArrayController = self.reflectorTableController;
//        addPopover?.contentViewController = addController
//        addPopover?.behavior = .semitransient
//        addPopover?.delegate = addController
//        bind(NSBindingName("txKeyCode"), to: NSUserDefaultsController.shared, withKeyPath: "values.shortcutValue", options: [NSBindingOption.valueTransformerName: MASDictionaryTransformerName])
//        view.window.makeFirstResponder(view)
//        view.window.initialFirstResponder = view
//        DSEDataEngine.sharedInstance().delegate = self
//        heardTableView.delegate = self
//        heardTableController.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
//        txButton.setPeriodicDelay(0.1, interval: 0.1)
//        txButtonState = NSControl.StateValue.off.rawValue
//        speechSynth = NSSpeechSynthesizer(voice: "com.apple.speech.synthesis.voice.samantha")
//        if speechSynth == nil {
//            print("Could not initialize speech synthesizer.")
//        }
//        geocoder = CLGeocoder()
//        assert(geocoder != nil, "Geocoder did not initialize")
//        volumeSlider = UserDefaults.standard.float(forKey: "outputVolume")
//        DSVars.shared().QSOCQController = self
//    }
//
    //-(void)destinationDidLink:(NSString *)destination {
    //    self.repeaterInfo.stringValue = [NSString stringWithFormat:@"Linked to %@", destination];
    //
    //    if([[NSUserDefaults standardUserDefaults] boolForKey:@"voiceAnnounceOnStatusChange"])
    //        [self.speechSynth startSpeakingString:[[NSString stringWithFormat:@"Linked to [[char LTRL]] %@ [[char NORM]]", destination] lowercaseString]];
    //
    //    NSDockTile *dockTile = [NSApplication sharedApplication].dockTile;
    //    dockTile.badgeLabel = destination;
    //    [dockTile display];
    //
    //    self.txButton.enabled = YES;
    //
    //}
    //
    //-(void)destinationDidUnlink:(NSString *)destination {
    //    self.repeaterInfo.stringValue = @"Unlinked";
    //
    //    if([[NSUserDefaults standardUserDefaults] boolForKey:@"voiceAnnounceOnStatusChange"])
    //        [self.speechSynth startSpeakingString:self.repeaterInfo.stringValue];
    //
    //    NSDockTile *dockTile = [NSApplication sharedApplication].dockTile;
    //    dockTile.badgeLabel = nil;
    //    [dockTile display];
    //
    //    self.txButton.enabled = NO;
    //    [self.reflectorTableView enumerateAvailableRowViewsUsingBlock:^void(NSTableRowView *rowView, NSInteger row) {
    //        NSTextField *reflectorsView = ((NSTableCellView *)[rowView viewAtColumn:0]).textField;
    //        if([reflectorsView.objectValue isEqualToString:destination])
    //            reflectorsView.textColor = [NSColor blackColor];
    //    }];
    //}
    //-(void)destinationDidError:(NSString *)destination error:(NSError *)error {
    //    NSAlert *alert = [NSAlert alertWithError:error];
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse response){}];
    //    });
    //}
    //
    //-(void)destinationWillLink:(NSString *)destination {
    //    self.repeaterInfo.stringValue = [NSString stringWithFormat:@"Linking to %@", destination];
    //}
    //-(void)destinationDidConnect:(NSString *)destination {
    //    self.repeaterInfo.stringValue = [NSString stringWithFormat:@"Connected to %@. Attempting to establish link.", destination];
    //}
    //
    //
    //- (IBAction)doHeardDoubleClick:(id)sender {
    //    NSLog(@"Got double click, row %ld column %ld", self.heardTableView.clickedRow, self.heardTableView.clickedColumn);
    //    if(self.heardTableView.clickedRow < 0)
    //        return;
    //
    //    NSDictionary *qso = self.heardTableController.arrangedObjects[self.heardTableView.clickedRow];
    //
    //    if(qso[@"location"]) {
    //        DSEAprsLocation *location = qso[@"location"];
    //        if(!location.callsign)
    //            location.callsign = qso[@"myCall"];
    //
    //        ((DSMapPopupController *)self.mapPopover.contentViewController).annotation = qso[@"location"];
    //        ((DSMapPopupController *)self.mapPopover.contentViewController).qsoId = qso[@"streamId"];
    //        NSView *clickedView = [self.heardTableView viewAtColumn:[self.heardTableView columnWithIdentifier:@"Location"] row:self.heardTableView.clickedRow makeIfNecessary:NO];
    //        [self.mapPopover showRelativeToRect:NSMakeRect(0, 0, 300, 300) ofView:clickedView preferredEdge:NSRectEdgeMaxY];
    //    }
    //}
    //-(IBAction)doReflectorDoubleClick:(id)sender {
    //    if(self.reflectorTableController.selectedObjects.count != 1) {
    //        NSBeep();
    //        return;
    //    }
    //
    //    NSString *reflector = self.reflectorTableController.selectedObjects[0][@"reflector"];
    //
    //    if(reflector.length < 8)
    //        return;
    //
    //    if([reflector isEqualToString:[DSEDataEngine sharedInstance].network.linkTarget]) {
    //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    //            [[DSEDataEngine sharedInstance] unlink];
    //        });
    //    } else {
    //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    //            [[DSEDataEngine sharedInstance] linkTo:reflector];
    //        });
    //    }
    //
    //    [self.reflectorTableView deselectAll:self];
    //}
    //- (IBAction)doLink:(id)sender {
    //    if(self.reflectorTableController.selectedObjects.count != 1) {
    //        NSBeep();
    //        return;
    //    }
    //
    //    NSString *reflector = self.reflectorTableController.selectedObjects[0][@"reflector"];
    //
    //    if(reflector.length < 8)
    //        return;
    //
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    //        [[DSEDataEngine sharedInstance] linkTo:reflector];
    //    });
    //
    //    [self.reflectorTableView deselectAll:self];
    //}
    //- (IBAction)doUnlink:(id)sender {
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    //        [[DSEDataEngine sharedInstance] unlink];
    //    });
    //
    //    [self.reflectorTableView deselectAll:self];
    //}
    @IBAction func doVolumeChange(_ sender: Any) {
        //        let engineaudio: DSAudioHandler? = DSEDataEngine.sharedInstance().audio
        //        engineaudio?.outputVolume = volumeSlider
        //        UserDefaults.standard.set(volumeSlider, forKey: "outputVolume")
    }

    @IBAction func reflectorChanged(_ sender: Any) {
    }
    
    @IBAction func connectReflector(_ sender: NSButton) {
        switch sender.state {
        case .on:
            sender.title = "Disconnect"
        case .off:
            sender.title = "Connect"
        default:
            break
        }
}

//    func addReflector(_ sender: Any?) {
//        if let aSender = sender as? NSView {
//            addPopover?.show(relativeTo: NSMakeRect(0, 0, 300, 300), of: aSender, preferredEdge: .maxY)
//        }
//    }

    func startTx() {
//        if !DSEDataEngine.sharedInstance().network {
        
//            NSBeep()
//            return
//        }
//        view.window.makeFirstResponder(view)
//        let audio: DSAudioHandler? = DSEDataEngine.sharedInstance().audio
//        audio?.xmit = true
    }

    func endTx() {
//        let audio: DSAudioHandler? = DSEDataEngine.sharedInstance().audio
//        audio?.xmit = false
//        statusLED.image = NSImage(named: NSImage.Name("Grey"))
    }

    @IBAction func doTx(_ sender: Any) {
//        if txButton.state == txButtonState {
//            startTx()
//        } else {
//            endTx()
//        }
//        txButtonState = txButton.state
    }

//// MARK: - Text Editing Control
//    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
//        DispatchQueue.main.async(execute: {
//            let result: Bool? = control.window?.makeFirstResponder(self.view)
//            if !(result ?? false) {
//                print("Would not resign first responder")
//            }
//        })
//        return true
//    }

// MARK: - Reflector cell validation
    //-(BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error {
    //    if(control != self.reflectorTableView) {
    //        NSLog(@"Control is not reflector list");
    //        return NO;
    //    }
    //    NSLog(@"Reflector string is invalid: %@", string);
    //
    //    [self.reflectorTableController remove:string];
    //
    //    NSAlert *alert = [[NSAlert alloc] init];
    //    alert.messageText = error;
    //    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse response){ }];
    //
    //    return YES;
    //}
    //
// MARK: - Heard List QSO Coloring
//    func resetColor(for rowView: NSTableRowView?, atRow row: Int) {
//        for i in 0..<(rowView?.numberOfColumns ?? 0) {
//            (rowView?.view(atColumn: i) as? NSTableCellView)?.textField?.textColor = heardTableController.arrangedObjects[row]["color"] as? NSColor
//        }
//    }
//
//    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
//        if tableView != heardTableView {
//            return
//        }
//        resetColor(for: rowView, atRow: row)
//        if mapPopover?.isShown != nil {
//            let popoverRow: Int = QSOCQViewController.findQsoId((mapPopover?.contentViewController as? DSMapPopupController)?.qsoId, inArray: heardTableController.arrangedObjects as? [Any])
//            assert(popoverRow != NSNotFound, "QSO ID \(popoverRow) not found in popover relocation")
//            let popoverAnchorView: NSView? = heardTableView.view(atColumn: heardTableView.column(withIdentifier: NSUserInterfaceItemIdentifier("Location")), row: popoverRow, makeIfNecessary: false)
//            if popoverAnchorView != nil && popoverRow == row {
//                if let aView = popoverAnchorView {
//                    mapPopover?.show(relativeTo: NSMakeRect(0, 0, 300, 300), of: aView, preferredEdge: .maxY)
//                }
//                (mapPopover?.contentViewController as? DSMapPopupController)?.suppressClose = false
//            }
//        }
//    }

// MARK: - Heard List Selection Control
//    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
//        if tableView == heardTableView {
//            return nil
//        }
//        if let anIndexes = proposedSelectionIndexes {
//            return anIndexes as IndexSet
//        }
//        return IndexSet()
//    }
//
//    func keyDown(_ theEvent: NSEvent) {
//        if theEvent.keyCode == txKeyCode.keyCode && !(view.window.isFirstResponder is NSTextView) {
//            if !theEvent.isARepeat {
//                startTx()
//            }
//        }
//    }
//
//    func keyUp(_ theEvent: NSEvent) {
//        if theEvent.keyCode == txKeyCode.keyCode && !(view.window.isFirstResponder is NSTextView) {
//            if !theEvent.isARepeat {
//                endTx()
//            }
//        }
//    }
//
//    func commitEditing() throws {
//        return false
//    }
//
//    func encode(with aCoder: NSCoder) {
//    }

}

extension HQSOCQViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        let count = reflectors?.gateways.count
        print("numberOfRows: \(count ?? 0)")
        return count ?? 0
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var result: NSTableCellView
        result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "firstName"), owner: self) as! NSTableCellView
        result.textField?.stringValue = "test"
        return result
    }

    func tableView(_: NSTableView, objectValueFor: NSTableColumn?, row: Int) -> Any? {
        let aReflector: DSReflector? = reflectors?.reflectorGateways()?[ row ] as? DSReflector
        if let object: NSUserInterfaceItemIdentifier = objectValueFor?.identifier {
            switch object.rawValue {
            case "ReflectorName":
                let value = object.rawValue
                return aReflector?.name

            case "ReflectorIP":
                return aReflector?.ip

            default:
                return "NONE"
            }
        }
        return "NONE"
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let aReflector: DSReflector? = reflectors?.reflectorGateways()?[ row ] as? DSReflector

    }

}

