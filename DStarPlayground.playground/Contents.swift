//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

class MyViewController : UIViewController {
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        let label = UILabel()
        label.frame = CGRect(x: 150, y: 200, width: 200, height: 20)
        label.text = "Hello World!"
        label.textColor = .black
        
        view.addSubview(label)
        self.view = view
    }
}
// Present the view controller in the Live View window
//PlaygroundPage.current.liveView = MyViewController()

struct dplus_packet {
    var length: UInt = 0
    var type = 0
    var padding = 0
    //    var frame: dstar_frame?
    subscript(attr: String) -> Any? {
        get {
            if attr == "length" { return length }
            if attr == "size" { return length & 0x0fff }
            if attr == "type" { return type }
            return nil
        }
        set {
            if attr == "length" { length = newValue as! UInt }
            if attr == "type" { type = newValue as! Int }
        }
    }
}
private var linkModuleTemplate = dplus_packet()
linkModuleTemplate["length"] = 0xc01c as UInt
linkModuleTemplate["length"]
