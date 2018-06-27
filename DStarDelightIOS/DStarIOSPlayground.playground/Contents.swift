//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

//class MyViewController : UIViewController {
//    override func loadView() {
//        let view = UIView()
//        view.backgroundColor = .white
//
//        let label = UILabel()
//        label.frame = CGRect(x: 150, y: 200, width: 200, height: 20)
//        label.text = "Hello World!"
//        label.textColor = .black
//
//        view.addSubview(label)
//        self.view = view
//    }
//}
// Present the view controller in the Live View window
//PlaygroundPage.current.liveView = MyViewController()
let call : String = "WD6EZL"
let t = String("C")
let digits = Array(call).map { Int(String($0)) }
for v in call {
    let x = Int8(v)
}
struct dcs_frame {
    var magic = [Int8](repeating: 0, count: 4)
    var flags = [Int8](repeating: 0, count: 3)
    var rpt2Call = [Int8](repeating: 0, count: 8)
    var rpt1Call = [Int8](repeating: 0, count: 8)
    var urCall = [Int8](repeating: 0, count: 8)
    var myCall = [Int8](repeating: 0, count: 8)
    var myCall2 = [Int8](repeating: 0, count: 4)
    var id: UInt16 = 0
    var sequence = 0
    var voice = [Int8](repeating: 0, count: 9)
    var data = [Int8](repeating: 0, count: 3)
    var repeaterSequence = [Int8](repeating: 0, count: 3)
    var unknown = [Int8](repeating: 0, count: 3)
    var text = [Int8](repeating: 0, count: 36)
}

let d = dcs_frame()
let d1 = d.urCall

//withUnsafeMutablePointer(&myVarOfStructProduct.name) {
//    strlcpy(UnsafeMutablePointer($0), productName, UInt(sizeofValue(myVarOfStructProduct.name)))
//}
