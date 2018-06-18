import AppKit
import Carbon.HIToolbox

func bridge<T : AnyObject>(obj : T) -> UnsafeRawPointer {
    return UnsafeRawPointer(Unmanaged.passUnretained(obj).toOpaque())
    // return unsafeAddressOf(obj) // ***
}

func bridge<T : AnyObject>(ptr : UnsafePointer<Any>) -> T {
    return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
    // return unsafeBitCast(ptr, T.self) // ***
}

func bridgeRetained<T : AnyObject>(obj : T) -> UnsafeRawPointer {
    return UnsafeRawPointer(Unmanaged.passRetained(obj).toOpaque())
}

func bridgeTransfer<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
    return Unmanaged<T>.fromOpaque(ptr).takeRetainedValue()
}

private let MASShortcutKeyCode = "KeyCode"
private let MASShortcutModifierFlags = "ModifierFlags"

enum Enum1 : Int {
    case kMASShortcutGlyphEject = 0x23cf
    case kMASShortcutGlyphClear = 0x2715
    case kMASShortcutGlyphDeleteLeft = 0x232b
    case kMASShortcutGlyphDeleteRight = 0x2326
    case kMASShortcutGlyphLeftArrow = 0x2190
    case kMASShortcutGlyphRightArrow = 0x2192
    case kMASShortcutGlyphUpArrow = 0x2191
    case kMASShortcutGlyphDownArrow = 0x2193
    case kMASShortcutGlyphEscape = 0x238b
    case kMASShortcutGlyphHelp = 0x003f
    case kMASShortcutGlyphPageDown = 0x21df
    case kMASShortcutGlyphPageUp = 0x21de
    case kMASShortcutGlyphTabRight = 0x21e5
    case kMASShortcutGlyphReturn = 0x2305
    case kMASShortcutGlyphReturnR2L = 0x21a9
    case kMASShortcutGlyphPadClear = 0x2327
    case kMASShortcutGlyphNorthwestArrow = 0x2196
    case kMASShortcutGlyphSoutheastArrow = 0x2198
}
func NSStringFromMASKeyCode(_ ch: UInt8) -> String? {
    return String(format: "%C", ch)
}
func MASPickCocoaModifiers(flags: UInt) -> UInt {
    return flags & (NSEvent.ModifierFlags.control.rawValue | NSEvent.ModifierFlags.shift.rawValue | NSEvent.ModifierFlags.option.rawValue | NSEvent.ModifierFlags.command.rawValue)
}

//func MASCarbonModifiersFromCocoaModifiers(cocoaFlags: UInt) -> UInt32  {
//    var mask: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
//    var flags = cocoaFlags | mask
//    }

class MASShortcut {
    
    /**
     The virtual key code for the keyboard key.
     Hardware independent, same as in `NSEvent`. See `Events.h` in the HIToolbox
     framework for a complete list, or Command-click this symbol: `kVK_ANSI_A`.
     */
    var keyCode: UInt = 0

    /**
     Cocoa keyboard modifier flags.
     Same as in `NSEvent`: `NSCommandKeyMask`, `NSAlternateKeyMask`, etc.
     */
    var modifierFlags: UInt = 0

    /**
     Same as `keyCode`, just a different type.
     */
    var carbonKeyCode: UInt32
    {
        get {
            return UInt32((keyCode == NSNotFound ? 0 : UInt32(keyCode)))
        }
//        set {
//          carbonKeyCode = newValue
//        }
    }

    /**
     Carbon modifier flags
     A bit sum of `cmdKey`, `optionKey`, etc.
     */
    var carbonFlags: UInt32 = 0

    /**
     A string representing the “key” part of a shortcut, like the `5` in `⌘5`.
     @warning The value may change depending on the active keyboard layout.
     For example for the `^2` keyboard shortcut (`kVK_ANSI_2+NSControlKeyMask`
     to be precise) the `keyCodeString` is `2` on the US keyboard, but `ě` when
     the Czech keyboard layout is active. See the spec for details.
     */
//    var keyCodeString = ""

    /**
     A key-code string used in key equivalent matching.
     
     For precise meaning of “key equivalents” see the `keyEquivalent`
     property of `NSMenuItem`. Here the string is used to support shortcut
     validation (“is the shortcut already taken in this menu?”) and
     for display in `NSMenu`.
     
     The value of this property may differ from `keyCodeString`. For example
     the Russian keyboard has a `Г` (Ge) Cyrillic character in place of the
     latin `U` key. This means you can create a `^Г` shortcut, but in menus
     that’s always displayed as `^U`. So the `keyCodeString` returns `Г`
     and `keyCodeStringForKeyEquivalent` returns `U`.
     */
//    var keyCodeStringForKeyEquivalent = ""

    /**
     A string representing the shortcut modifiers, like the `⌘` in `⌘5`.
     */
//    var modifierFlagsString = ""

    // MARK: Initialization
    init(withKeyCode code: UInt, modifierFlags: UInt) {
        self.keyCode = code
        self.modifierFlags = MASPickCocoaModifiers(flags: modifierFlags)
    }
    
    convenience init(shortcutWithKeyCode code: UInt, modifierFlags flags: UInt) {
        self.init(withKeyCode: code, modifierFlags: flags)
    }

    /**
     Creates a new shortcut from an `NSEvent` object.
     This is just a convenience initializer that reads the key code and modifiers from an `NSEvent`.
     */
    convenience init(shortcutWithEvent: NSEvent?) {
        if shortcutWithEvent != nil {
            let event = shortcutWithEvent!
            let eCode: UInt = UInt(event.keyCode)
            let eFlags: UInt = UInt(event.modifierFlags.rawValue)
            self.init(shortcutWithKeyCode: eCode, modifierFlags: eFlags)
        } else {
            self.init(withKeyCode: 0, modifierFlags: 0)
        }
    }

    // MARK: Shortcut Accessors
//    func carbonFlags() -> UInt32 {
//        return MASCarbonModifiersFromCocoaModifiers(modifierFlags)
//    }

    func description() -> String? {
        return "\(modifierFlagsString() ?? "")\(keyCodeString() ?? "")"
    }

    func keyCodeStringForKeyEquivalent() -> String? {
        let keyCodeString = self.keyCodeString()
        if (keyCodeString?.count ?? 0) > 1 {
            switch keyCode {
            case UInt(kVK_F1):
                return NSStringFromMASKeyCode(UInt8(0xf704))
            case UInt(kVK_F2):
                return NSStringFromMASKeyCode(UInt8(0xf705))
            case UInt(kVK_F3):
                return NSStringFromMASKeyCode(UInt8(0xf706))
            case UInt(kVK_F4):
                return NSStringFromMASKeyCode(UInt8(0xf707))
            case UInt(kVK_F5):
                return NSStringFromMASKeyCode(UInt8(0xf708))
            case UInt(kVK_F6):
                return NSStringFromMASKeyCode(UInt8(0xf709))
            case UInt(kVK_F7):
                return NSStringFromMASKeyCode(UInt8(0xf70a))
            case UInt(kVK_F8):
                return NSStringFromMASKeyCode(UInt8(0xf70b))
            case UInt(kVK_F9):
                return NSStringFromMASKeyCode(UInt8(0xf70c))
            case UInt(kVK_F10):
                return NSStringFromMASKeyCode(UInt8(0xf70d))
            case UInt(kVK_F11):
                return NSStringFromMASKeyCode(UInt8(0xf70e))
            case UInt(kVK_F12):
                return NSStringFromMASKeyCode(UInt8(0xf70f))
            case UInt(kVK_F13):
                return NSStringFromMASKeyCode(UInt8(0xf710))
            case UInt(kVK_F14):
                return NSStringFromMASKeyCode(UInt8(0xf711))
            case UInt(kVK_F15):
                return NSStringFromMASKeyCode(UInt8(0xf712))
            case UInt(kVK_F16):
                return NSStringFromMASKeyCode(UInt8(0xf713))
            case UInt(kVK_F17):
                return NSStringFromMASKeyCode(UInt8(0xf714))
            case UInt(kVK_F18):
                return NSStringFromMASKeyCode(UInt8(0xf715))
            case UInt(kVK_F19):
                return NSStringFromMASKeyCode(UInt8(0xf716))
            case UInt(kVK_Space):
                return NSStringFromMASKeyCode(UInt8(0x20))
            default:
                return ""
            }
        }
        return keyCodeString?.lowercased()
    }
    func    keyName       ( scanCode: UInt16  )     ->  String? {
        let maxNameLength = 4,      modifierKeys: UInt32  = 0x00000004,     //  Caps Lock (Carbon Era Mask)
        nameBuffer    = UnsafeMutablePointer <UniChar>  .allocate (capacity: maxNameLength),
        nameLength    = UnsafeMutablePointer <Int>      .allocate (capacity: 1),
        deadKeys      = UnsafeMutablePointer <UInt32>   .allocate (capacity: 1);     deadKeys[0] = 0x00000000
        
        let source        = TISGetInputSourceProperty ( TISCopyCurrentKeyboardLayoutInputSource()
            .takeRetainedValue(),
                                                        kTISPropertyUnicodeKeyLayoutData  ),
        
        keyboardLayout    = unsafeBitCast ( CFDataGetBytePtr (unsafeBitCast (source, to: CFData.self)),
                                            to: UnsafePointer <UCKeyboardLayout>.self),
        keyboardType      = UInt32 (LMGetKbdType())
        
        let osStatus      = UCKeyTranslate (keyboardLayout, scanCode, UInt16 (kUCKeyActionDown),
                                            modifierKeys, keyboardType, UInt32 (kUCKeyTranslateNoDeadKeysMask),
                                            deadKeys, maxNameLength, nameLength, nameBuffer)
        switch  osStatus {
        case  0:    return  String.init (utf16CodeUnits: nameBuffer, count: nameLength[0])
        default:    NSLog ("Code: 0x%04X  Status: %+i", scanCode, osStatus);    return  nil
            
        }
    }
    func keyCodeString() -> String? {
        // Some key codes don't have an equivalent
        switch keyCode {
        case UInt(NSNotFound):
            return ""
        case  UInt(kVK_F1):
            return "F1"
        case  UInt(kVK_F2):
            return "F2"
        case  UInt(kVK_F3):
            return "F3"
        case  UInt(kVK_F4):
            return "F4"
        case  UInt(kVK_F5):
            return "F5"
        case  UInt(kVK_F6):
            return "F6"
        case  UInt(kVK_F7):
            return "F7"
        case  UInt(kVK_F8):
            return "F8"
        case  UInt(kVK_F9):
            return "F9"
        case  UInt(kVK_F10):
            return "F10"
        case  UInt(kVK_F11):
            return "F11"
        case  UInt(kVK_F12):
            return "F12"
        case  UInt(kVK_F13):
            return "F13"
        case  UInt(kVK_F14):
            return "F14"
        case  UInt(kVK_F15):
            return "F15"
        case  UInt(kVK_F16):
            return "F16"
        case  UInt(kVK_F17):
            return "F17"
        case  UInt(kVK_F18):
            return "F18"
        case  UInt(kVK_F19):
            return "F19"
        case  UInt(kVK_Space):
            return NSLocalizedString("Space", comment: "Shortcut glyph name for SPACE key")
        case  UInt(kVK_Escape):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphEscape.rawValue))
        case  UInt(kVK_Delete):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphDeleteLeft.rawValue))
        case  UInt(kVK_ForwardDelete):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphDeleteRight.rawValue))
        case  UInt(kVK_LeftArrow):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphLeftArrow.rawValue))
        case  UInt(kVK_RightArrow):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphRightArrow.rawValue))
        case  UInt(kVK_UpArrow):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphUpArrow.rawValue))
        case  UInt(kVK_DownArrow):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphDownArrow.rawValue))
        case  UInt(kVK_Help):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphHelp.rawValue))
        case  UInt(kVK_PageUp):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphPageUp.rawValue))
        case  UInt(kVK_PageDown):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphPageDown.rawValue))
        case  UInt(kVK_Tab):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphTabRight.rawValue))
        case  UInt(kVK_Return):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphReturnR2L.rawValue))
        case  UInt(kVK_ANSI_Keypad0):
            return "0"
        case  UInt(kVK_ANSI_Keypad1):
            return "1"
        case  UInt(kVK_ANSI_Keypad2):
            return "2"
        case  UInt(kVK_ANSI_Keypad3):
            return "3"
        case  UInt(kVK_ANSI_Keypad4):
            return "4"
        case  UInt(kVK_ANSI_Keypad5):
            return "5"
        case  UInt(kVK_ANSI_Keypad6):
            return "6"
        case  UInt(kVK_ANSI_Keypad7):
            return "7"
        case  UInt(kVK_ANSI_Keypad8):
            return "8"
        case  UInt(kVK_ANSI_Keypad9):
            return "9"
        case  UInt(kVK_ANSI_KeypadDecimal):
            return "."
        case  UInt(kVK_ANSI_KeypadMultiply):
            return "*"
        case  UInt(kVK_ANSI_KeypadPlus):
            return "+"
        case  UInt(kVK_ANSI_KeypadClear):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphPadClear.rawValue))
        case  UInt(kVK_ANSI_KeypadDivide):
            return "/"
        case  UInt(kVK_ANSI_KeypadEnter):
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphReturn.rawValue))
        case  UInt(kVK_ANSI_KeypadMinus):
            return "–"
        case  UInt(kVK_ANSI_KeypadEquals):
            return "="
        case 119:
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphSoutheastArrow.rawValue))
        case 115:
            return NSStringFromMASKeyCode(UInt8(Enum1.kMASShortcutGlyphNorthwestArrow.rawValue))
        default:
            let kUInt16 = UInt16(keyCode)
            let keystroke = keyName(scanCode: kUInt16)
//            // Everything else should be printable so look it up in the current ASCII capable keyboard layout
//            var error: OSStatus = 0
//            var keystroke: String? = nil
//            let inputSource: TISInputSource = TISCopyCurrentASCIICapableKeyboardLayoutInputSource() as! TISInputSource
//            //        if inputSource != nil {
//            let layoutDataRef = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData) as! CFData
//            //        if layoutDataRef != nil {
//            let layoutData = CFDataGetBytePtr(layoutDataRef)
//            let layoutDataPtr = UnsafeRawPointer(layoutData).unsafelyUnwrapped.bindMemory(to: UCKeyboardLayout.self, capacity: 1)
//            var length = 0
//            var layoutChars: [UniChar] = [0] as [UniChar]
//            var deadKeyState: UInt32 = 0
//            error = UCKeyTranslate(
//                layoutDataPtr,
//                UInt16(keyCode),
//                UInt16(kUCKeyActionDisplay),
//                0,                 // No modifiers
//                UInt32(LMGetKbdType()),
//                OptionBits(kUCKeyTranslateNoDeadKeysMask),
//                &deadKeyState,
//                MemoryLayout<UniChar>.size / MemoryLayout<UniChar>.size,
//                &length,
//                &layoutChars)
//            keystroke = ((error == noErr) && (length != 0)) ? String(utf16CodeUnits: layoutChars, count: length) : ""
//            //        }
//            //        }
//            // Validate keystroke
//            if (keystroke?.count ?? 0) != 0 {
//                var validChars: CharacterSet? = nil
//                if validChars == nil {
//                    validChars = CharacterSet()
//                    validChars?.formUnion(CharacterSet.alphanumerics)
//                    validChars?.formUnion(CharacterSet.punctuationCharacters)
//                    validChars?.formUnion(CharacterSet.symbols)
//                }
//                var i = 0, length = (keystroke?.count ?? 0)
//                while i < length {
//                    let c = keystroke?.characters
//                    if !(validChars?.characterIsMember(unichar(keystroke?[keystroke?.index(keystroke?.startIndex, offsetBy: i)] ?? 0)) ?? false) {
//                        keystroke = ""
//                        break
//                    }
//                    i += 1
//                }
//            }
            // Finally, we've got a shortcut!
            if keystroke == nil {
                return ""
            } else {
                return keystroke?.uppercased()
            }
        }
    }
    
    func modifierFlagsString() -> String? {
        var modifiers = [unichar](repeating: 0, count: 4)
        var count: Int = 0
        // These are in the same order as the menu manager shows them
        if modifierFlags & UInt(NSEvent.ModifierFlags.control.rawValue) != 0 {
            modifiers[count] = UInt16(kControlUnicode)
            count += 1
        }
        if modifierFlags & UInt(NSEvent.ModifierFlags.option.rawValue) != 0 {
            modifiers[count] = UInt16(kOptionUnicode)
            count += 1
        }
        if modifierFlags & UInt(NSEvent.ModifierFlags.shift.rawValue) != 0 {
            modifiers[count] = UInt16(kShiftUnicode)
            count += 1
        }
        if modifierFlags & UInt(NSEvent.ModifierFlags.command.rawValue) != 0 {
            modifiers[count] = UInt16(kCommandUnicode)
            count += 1
        }
        return count != 0 ? String(utf16CodeUnits: modifiers, count: count) : ""
    }
}

// MARK: NSSecureCoding
    var supportsSecureCoding: Bool = true
