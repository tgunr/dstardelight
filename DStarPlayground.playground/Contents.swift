//: A UIKit based Playground for presenting user interface
  
import PlaygroundSupport

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

func makeIncrementer(forIncrement amount: Int) -> () -> Int {
    var rt = 0
    func inc() -> Int {
        rt += amount
        return rt
    }
    return inc
}

let inc2 = makeIncrementer(forIncrement: 2)
inc2()
inc2()
let inc3 = makeIncrementer(forIncrement: 3)
inc3()
inc3()

let clos1 = { () -> Void in
    print("Hello")
}
clos1()

let clos2 = {
    (name: String) -> Void in
    print("Hello \(name)")
}

clos2("test")

func testClosure(handler: (String) -> Void) {
    handler("Dasher")
}

let clos3 = {
    (name: String) -> String in
    return "Hello \(name)"
}

testClosure(handler: clos2)

var message = clos3("Buddy")

func test2(_ aString: String) {
    print("aString: \(aString)")
}

test2("one")
test2(clos3("two"))

func testFunction(num: Int, handler: () -> Void ) {
    for _ in 0..<num {
        handler()
    }
}

let clos = {
    () -> Void in
    print("Hello from standard sytax")
}

testFunction(num: 3, handler: clos)
testFunction(num: 4, handler: { print("Hello again") })

func testFunction2(num: Int, handler: (_ : String)->Void) {
  for _ in 0..<num {
    handler("Me")
  }
}

testFunction2(num: 5){
  print("Hello from \($0)")
}

private var qsoList: [ [AnyHashable : Any] ]  = [ [ : ] ]

func updateQsoId(_ streamId: Int?, usingBlock block: @escaping ([AnyHashable : Any], Int) -> Void) -> Bool {
    let qsoIndex: Int = 0
    if qsoIndex == NSNotFound {
        return false
    }
    var qso = qsoList[qsoIndex]
    block(qso, qsoIndex)
    return true
}

var updated = updateQsoId(1, usingBlock: { qso, qsoIndex in })
var test = updateQsoId(1, usingBlock: { qso, qsoIndex in
    print("here")
    var aQso = Date()
    if aQso != nil {
        qso["duration"] = Date().timeIntervalSince(aQso)
    }
})

