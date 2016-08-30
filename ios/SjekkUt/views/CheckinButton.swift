//
//  CheckinButton.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 25/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class CheckinButton: UIButton {

    var circleColor: UIColor = DntColor.red() {
        didSet {
            backgroundColor = circleColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.size.width / 2
        self.layer.masksToBounds = false
    }
}