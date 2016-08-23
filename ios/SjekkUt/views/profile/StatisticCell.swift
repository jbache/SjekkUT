//
//  StatisticCell.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 19/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class StatisticCell: UICollectionViewCell {

    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var statLabel: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
        let scaleFactor = UIScreen.mainScreen().bounds.width/320
        circleView.layer.cornerRadius = scaleFactor * circleView.bounds.size.width / 2
        circleView.layer.masksToBounds = false
    }
}