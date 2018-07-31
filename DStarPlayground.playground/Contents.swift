//: A UIKit based Playground for presenting user interface
  
import PlaygroundSupport
import RxSwift

#if os(OSX)
import AppKit
import Cocoa
typealias ColorType = NSColor
typealias ViewType = NSView
typealias LabelType = NSLable
#elseif os(iOS)
import UIKit
typealias ColorType = UIColor
typealias ImageType = UIImage
typealias ViewType = UIView
#endif
