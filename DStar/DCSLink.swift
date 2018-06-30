//
//  DCSLink.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/27/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation

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

struct dcs_poll {
    var callsign = [Int8](repeating: 0, count: 8)
    var null = 0
    var reflectorCall = [Int8](repeating: 0, count: 8)
}

var callsign = [Int8](repeating: 0, count: 8)
var module = 0
var reflectorModule = 0
var frame: dcs_frame?

private var dcsFrameTemplate = dcs_frame()

func dcsFrameTemplateInit () {
    dcsFrameTemplate.magic = [0, 0, 0, 1]
    //dcsFrameTemplate.magic = "0001"
    //dcsFrameTemplate.flags = 0x00
    dcsFrameTemplate.rpt2Call = [32, 32, 32, 32, 32, 32, 32, 32]
    dcsFrameTemplate.rpt1Call = [32, 32, 32, 32, 32, 32, 32, 32]
    let urCallString = "CQCQCQ  "
//    dcsFrameTemplate.urCall = Array(urCallString) as [Int8]
//    dcsFrameTemplate.myCall = "        " as? dcs_frame
//    dcsFrameTemplate.myCall2 = "    " as? dcs_frame
//    dcsFrameTemplate.id = 0 as? dcs_frame
//    dcsFrameTemplate.sequence = 0 as? dcs_frame
//    dcsFrameTemplate.voice = [0] as? dcs_frame
//    dcsFrameTemplate.data = [0] as? dcs_frame
//    dcsFrameTemplate.repeaterSequence = [0] as? dcs_frame
//    dcsFrameTemplate.unknown = [0] as? dcs_frame
//    dcsFrameTemplate.text = [0] as? dcs_frame
//    dcsFrameTemplate.linkTemplate = dcs_packet()
//    linkTemplate.link.callsign = "        "
//    linkTemplate.link.module = "D"
//    linkTemplate.link.reflectorModule = " "
//    linkTemplate.link.request.terminator = 0x00
//    linkTemplate.link.request.reflectorCall = "        "
//    linkTemplate.link.request.htmlData = 0x00
}
private var _reflectorList = [AnyHashable: Any]()

class DSEDCSLink {
    private var repeaterSequence: Int = 0

//    class private func reflectorList() -> [AnyHashable: Any]? {
//    }
//
//    private func processFrame(_ frame: dcs_frame?) {
//    }
}
