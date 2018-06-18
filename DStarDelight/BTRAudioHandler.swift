//
//  AudioHandler.swift
//  Buster
//
//  Created by Dave Carlton on 6/11/18.
//  Copyright © 2018 NH6Z. All rights reserved.
//

import AudioToolbox

enum InOut {
    case In, Out
}

// CustomStringConvertible is defined elsewhere
extension AudioObjectPropertySelector {
    var description :String {
        get {
            switch self {
            case kAudioObjectPropertyName:
                return "name"
            case kAudioObjectPropertyManufacturer:
                return "manufacturer"
            case kAudioObjectPropertyModelName:
                return "modelName"
            case kAudioObjectPropertyClass:
                return "class"
            case kAudioObjectPropertyOwner:
                return "owner"
            case kAudioObjectPropertyCreator:
                return "creator"
            case kAudioObjectPropertyElementName:
                return "elementName"
            case kAudioObjectPropertyElementCategoryName:
                return "elementCategoryName"
            case kAudioObjectPropertyElementNumberName:
                return "elementNumberName"
            case kAudioObjectPropertySerialNumber:
                return "serialNumber"
            case kAudioObjectPropertyFirmwareVersion:
                return "firmwareVersion"
            default:
                return "unknown"
            }
        }
    }
}

enum Property :String {
    case name, manufacturer, modelName, klass, owner, creator, elementName, elementCategoryName, elementNumberName, serialNumber, firmwareVersion
    
    func audioObjectPropertyName() -> AudioObjectPropertySelector {
        switch self {
        case .name:
            return kAudioObjectPropertyName
        case .manufacturer:
            return kAudioObjectPropertyManufacturer
        case .modelName:
            return kAudioObjectPropertyModelName
        case .klass:
            return kAudioObjectPropertyClass
        case .owner:
            return kAudioObjectPropertyOwner
        case .creator:
            return kAudioObjectPropertyCreator
        case .elementName:
            return kAudioObjectPropertyElementName
        case .elementNumberName:
            return kAudioObjectPropertyElementNumberName
        case .elementCategoryName:
            return kAudioObjectPropertyElementCategoryName
        case .serialNumber:
            return kAudioObjectPropertySerialNumber
        case .firmwareVersion:
            return kAudioObjectPropertyFirmwareVersion
        }
    }
    
    static func all() -> [Property] {
        return [.name, .manufacturer, .modelName, .klass, .owner, .creator, .elementName, .elementCategoryName, .elementNumberName, .serialNumber, .firmwareVersion]
    }
}

struct AudioDevice {
    let id :AudioObjectID
    let inOut :InOut
    let selected :Bool
    let properties :[String:String]
    
    init(id :AudioObjectID, inOut :InOut, selected :Bool) {
        self.id = id
        self.inOut = inOut
        self.selected = selected
        
        var p = [String:String]()
        // other properties fails to access
        [Property]([.name, .manufacturer]).forEach { property in
            if let val = getProperty(of: id, selector: property.audioObjectPropertyName()) {
                p[ property.rawValue ] = val
            }
        }
        self.properties = p
    }
}

func selectedAudioObject(inOut :InOut) -> AudioObjectID? {
    var deviceID:AudioObjectID = AudioObjectID(0)
    var size:UInt32 = UInt32(MemoryLayout<AudioObjectID>.size)
    var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress()
    if inOut == .In {
        address.mSelector = kAudioHardwarePropertyDefaultInputDevice
    }
    else {
        address.mSelector = kAudioHardwarePropertyDefaultOutputDevice
    }
    address.mScope = kAudioObjectPropertyScopeGlobal
    address.mElement = kAudioObjectPropertyElementMaster
    let err1 = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
    if err1 != 0 {
        print("error: \(err1)")
        return nil
    }
    return deviceID
}

func currentAudioDevices() -> [AudioDevice] {
    let ins = enumerateDevices(inOut: .In)
    let outs = enumerateDevices(inOut: .Out)
    let selectedIn = selectedAudioObject(inOut: .In)
    let selectedOut = selectedAudioObject(inOut: .Out)
    let inDevices = ins.compactMap { (id) -> AudioDevice? in
        return AudioDevice(id: id, inOut: .In, selected: id == selectedIn)
    }
    let outDevices = outs.compactMap { (id) -> AudioDevice? in
        return AudioDevice(id: id, inOut: .Out, selected: id == selectedOut)
    }
    return inDevices + outDevices
}

func enumerateDevices(inOut :InOut) -> [AudioObjectID] {
    var deviceIDs:[AudioObjectID]
    var size:UInt32 = UInt32(MemoryLayout<[AudioObjectID]>.size)
    var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress()
    address.mSelector = kAudioHardwarePropertyDevices
    if inOut == .In {
        address.mScope = kAudioObjectPropertyScopeInput
    }
    else {
        address.mScope = kAudioObjectPropertyScopeOutput
    }
    address.mElement = kAudioObjectPropertyElementMaster
    let err1 = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size)
    if err1 != 0 {
        print("error: \(err1)")
        return []
    }
    deviceIDs = [AudioObjectID](repeating: 0, count: Int(size/UInt32(MemoryLayout<AudioObjectID>.size)))
    let err2 = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceIDs)
    if err2 != 0 {
        print("error: \(err2)")
        return []
    }
    return deviceIDs
}

func getProperty(of id :AudioObjectID, selector :AudioObjectPropertySelector) -> String? {
    var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress()
    address.mSelector = selector
    address.mScope = kAudioObjectPropertyScopeGlobal
    address.mElement = kAudioObjectPropertyElementMaster
    
    var deviceName :CFString? = nil
    var size = UInt32(MemoryLayout<String>.size)
    let err1 = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &deviceName)
    if err1 != 0 {
        print("failed to get property: \(selector.description), error: \(err1)")
        return nil
    }
    return deviceName as String?
}

func getDevicePropertyData(deviceid: AudioDeviceID, selector: AudioObjectPropertySelector) -> String {
    // Query device manufacturer
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(selector),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    var propertySize = UInt32(MemoryLayout<CFString>.size)
    var result: CFString = "" as CFString

    let status: OSStatus = AudioObjectGetPropertyData(deviceid, &propertyAddress, 0, nil, &propertySize, &result)

    if kAudioHardwareNoError != status {
        NSLog("AudioObjectGetPropertyDataSize: failed: %s status: %i\n", selector, status)
    }

    return result as String
}

func getDevicePropertyDataSize(deviceid: AudioDeviceID, selector: AudioObjectPropertySelector) -> UInt32 {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    var propertySize: UInt32 = 0

    let status: OSStatus = AudioObjectGetPropertyDataSize(deviceid, &propertyAddress, 0, nil, &propertySize)

    if kAudioHardwareNoError != status {
        NSLog("AudioObjectGetPropertyDataSize: failed: status: %i\n", status)
    }

    return propertySize / UInt32(MemoryLayout<AudioDeviceID>.size)
}

func CreateInputDeviceArray() -> [String: String]? {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMaster)
    
    var status: OSStatus = kAudioHardwareNoError
    var propertySize: UInt32 = 0
    status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize)
    if kAudioHardwareNoError != status {
        NSLog("AudioObjectGetPropertyDataSize (kAudioHardwarePropertyDevices) failed: %i\n", status)
        return nil
    }
    let deviceCount: UInt32 = (UInt32)(Int(propertySize) / MemoryLayout<AudioDeviceID>.size)
    var audioDeviceIDs = [AudioDeviceID](repeating: 0, count: Int(deviceCount))
    if audioDeviceIDs.count == 0 {
        NSLog("Unable to allocate memory", stderr)
        return nil
    }
    status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &audioDeviceIDs)
    if kAudioHardwareNoError != status {
        NSLog("AudioObjectGetPropertyData (kAudioHardwarePropertyDevices) failed: %i\n", status)
        return nil
    }
    _ = [Any](repeating: 0, count: Int(deviceCount))
    let deviceDictionary: Dictionary<String, String> = [:]
    // Iterate through all the devices and determine which are input-capable
    propertyAddress.mScope = kAudioDevicePropertyScopeInput
    for device in audioDeviceIDs {
        let deviceName = getDevicePropertyData(deviceid: device, selector: kAudioDevicePropertyDeviceNameCFString)
        let deviceManufactuer = getDevicePropertyData(deviceid: device, selector: kAudioDevicePropertyDeviceManufacturerCFString)
        //        let inputType = isInputDevice(deviceID: device)
        let deviceUID = getDevicePropertyData(deviceid: deviceCount, selector: kAudioDevicePropertyDeviceUID)
        _ = getDevicePropertyData(deviceid: device, selector: kAudioDevicePropertyStreamConfiguration)
        //            let bufferList = malloc(propertySize) as? AudioBufferList
        //            status = AudioObjectGetPropertyData(audioDeviceIDs[i], &propertyAddress, 0, nil, &propertySize, bufferList)
        // Add a dictionary for this device to the array of input devices
        _ = ["deviceUID": deviceUID, "deviceName": deviceName, "deviceManufacturer": deviceManufactuer]
    }
    return deviceDictionary
}

func getDeviceManufactuer(deviceID: AudioDeviceID) -> String {
    // Query device manufacturer
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioDevicePropertyDeviceManufacturerCFString),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    var propertySize = UInt32(MemoryLayout<CFString>.size)
    var result: CFString = "" as CFString
    let status: OSStatus = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &result)
    if kAudioHardwareNoError != status {
        NSLog("AudioObjectGetPropertyData (kAudioDevicePropertyDeviceManufacturerCFString) failed: %i\n", status)
    }
    return result as String
}

func getInputDevices() {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMaster)
    
    var propertySize: UInt32 = 0
    
    var status: OSStatus = AudioObjectGetPropertyDataSize(
        AudioObjectID(kAudioObjectSystemObject),
        &propertyAddress,
        0,
        nil,
        &propertySize)
    
    //    let deviceCount = getNumberOfDevices()
    //        let deviceCount = propertySize / UInt32(MemoryLayout<AudioDeviceID>.size)
    let asize = UInt32(MemoryLayout<AudioDeviceID>.size)
    let deviceCount = propertySize / asize
    
    var devices = [AudioDeviceID](repeating: 0, count: Int(deviceCount))
    status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &devices)
    propertyAddress.mSelector   = kAudioDevicePropertyStreams
    propertyAddress.mScope = kAudioDevicePropertyScopeInput
    
    var isInput: Bool = false
    for device in devices {
        status = AudioObjectGetPropertyDataSize(device, &propertyAddress, 0, nil, &propertySize)
        let s: UInt32 = UInt32(MemoryLayout.size(ofValue: AudioStreamID()))
        let streamCount = propertySize / s
        if (streamCount > 0) {
            isInput = true
        }
    }
}

func getOutputDevices() -> [AudioDeviceID: String]? {
    var result: [AudioDeviceID: String] = [:]
    let devices = getAllDevices()
    
    for device in devices {
        if isOutputDevice(deviceID: device) {
            result[device] = getDeviceName(deviceID: device)
        }
    }
    
    return result
}

func isOutputDevice(deviceID: AudioDeviceID) -> Bool {
    var propertySize: UInt32 = 256
    
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioDevicePropertyStreams),
        mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    
    _ = AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &propertySize)
    
    return propertySize > 0
}

func getAggregateDeviceSubDeviceList(deviceID: AudioDeviceID) -> [AudioDeviceID] {
    let subDevicesCount = getNumberOfSubDevices(deviceID: deviceID)
    var subDevices = [AudioDeviceID](repeating: 0, count: Int(subDevicesCount))
    
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioAggregateDevicePropertyActiveSubDeviceList),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    
    var subDevicesSize = subDevicesCount * UInt32(MemoryLayout<UInt32>.size)
    
    AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &subDevicesSize, &subDevices)
    
    return subDevices
}

func isAggregateDevice(deviceID: AudioDeviceID) -> Bool {
    let deviceType = getDeviceTransportType(deviceID: deviceID)
    return deviceType == kAudioDeviceTransportTypeAggregate
}

func setDeviceVolume(deviceID: AudioDeviceID, leftChannelLevel: Float, rightChannelLevel: Float) {
    let channelsCount = 2
    var channels = [UInt32](repeating: 0, count: channelsCount)
    var propertySize = UInt32(MemoryLayout<UInt32>.size * channelsCount)
    var leftLevel = leftChannelLevel
    var rigthLevel = rightChannelLevel
    
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioDevicePropertyPreferredChannelsForStereo),
        mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    
    let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &channels)
    
    if status != noErr { return }
    
    propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar
    propertySize = UInt32(MemoryLayout<Float32>.size)
    propertyAddress.mElement = channels[0]
    
    AudioObjectSetPropertyData(deviceID, &propertyAddress, 0, nil, propertySize, &leftLevel)
    
    propertyAddress.mElement = channels[1]
    
    AudioObjectSetPropertyData(deviceID, &propertyAddress, 0, nil, propertySize, &rigthLevel)
}

func setOutputDevice(newDeviceID: AudioDeviceID) {
    let propertySize = UInt32(MemoryLayout<UInt32>.size)
    var deviceID = newDeviceID
    
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    
    AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, propertySize, &deviceID)
}

func getDeviceVolume(deviceID: AudioDeviceID) -> [Float] {
    let channelsCount = 2
    var channels = [UInt32](repeating: 0, count: channelsCount)
    var propertySize = UInt32(MemoryLayout<UInt32>.size * channelsCount)
    var leftLevel = Float32(-1)
    var rigthLevel = Float32(-1)
    
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioDevicePropertyPreferredChannelsForStereo),
        mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    
    let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &channels)
    
    if status != noErr { return [-1] }
    
    propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar
    propertySize = UInt32(MemoryLayout<Float32>.size)
    propertyAddress.mElement = channels[0]
    
    AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &leftLevel)
    
    propertyAddress.mElement = channels[1]
    
    AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &rigthLevel)
    
    return [leftLevel, rigthLevel]
}

func getDefaultOutputDevice() -> AudioDeviceID {
    var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
    var deviceID = kAudioDeviceUnknown
    
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &deviceID)
    
    return deviceID
}

func getDeviceTransportType(deviceID: AudioDeviceID) -> AudioDevicePropertyID {
    var deviceTransportType = AudioDevicePropertyID()
    var propertySize = UInt32(MemoryLayout<AudioDevicePropertyID>.size)
    
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioDevicePropertyTransportType),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    
    AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &deviceTransportType)
    
    return deviceTransportType
}

func getNumberOfDevices() -> UInt32 {
    var propertySize: UInt32 = 0
    
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    
    _ = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize)
    
    return propertySize / UInt32(MemoryLayout<AudioDeviceID>.size)
}

func getNumberOfSubDevices(deviceID: AudioDeviceID) -> UInt32 {
    var propertySize: UInt32 = 0
    
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioAggregateDevicePropertyActiveSubDeviceList),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    
    _ = AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &propertySize)
    
    return propertySize / UInt32(MemoryLayout<AudioDeviceID>.size)
}

func getDeviceName(deviceID: AudioDeviceID) -> String {
    var propertySize = UInt32(MemoryLayout<CFString>.size)
    
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioDevicePropertyDeviceNameCFString),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    
    var result: CFString = "" as CFString
    
    AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &result)
    
    return result as String
}

func getAllDevices() -> [AudioDeviceID] {
    let devicesCount = getNumberOfDevices()
    var devices = [AudioDeviceID](repeating: 0, count: Int(devicesCount))
    
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
    
    var devicesSize = devicesCount * UInt32(MemoryLayout<UInt32>.size)
    
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &devicesSize, &devices)
    
    return devices
}

@objc
class BTRAudioHandler: NSObject {
    class func enumerateInputDevices() -> [Dictionary<String, Any>] {
        var result:[Dictionary<String, Any>]  = []
        let devices = enumerateDevices(inOut: .In)
        var audioDevice: Dictionary<String, Any> = [:]
        for device in devices {
            audioDevice.updateValue(device as AudioDeviceID, forKey: "id")
            let name = getDeviceName(deviceID: device)
            audioDevice.updateValue(name, forKey: "description")
            let uid = getDevicePropertyData(deviceid: device, selector: kAudioDevicePropertyDeviceUID)
            audioDevice.updateValue(uid, forKey: "uid")
            result.append(audioDevice)
        }
        return result
    }
    
    class func enumerateOutputDevices() -> [Dictionary<String, Any>] {
        var result:[Dictionary<String, Any>]  = []
        let devices = enumerateDevices(inOut: .Out)
        var audioDevice: Dictionary<String, Any> = [:]
        for device in devices {
            audioDevice.updateValue(device as AudioDeviceID, forKey: "id")
            let name = getDeviceName(deviceID: device)
            audioDevice.updateValue(name, forKey: "description")
            let uid = getDevicePropertyData(deviceid: device, selector: kAudioDevicePropertyDeviceUID)
            audioDevice.updateValue(uid, forKey: "uid")
            result.append(audioDevice)
        }
        return result
    }
}
