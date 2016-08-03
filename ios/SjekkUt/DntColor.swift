//
//  DntColor.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 04/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

// thanks to http://stackoverflow.com/a/24263296/50830
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

class DntColor {
    static func red() -> UIColor {
        return UIColor(netHex: 0xd82d20)
    }
}