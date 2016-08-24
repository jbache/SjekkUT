//
//  CheckinCell.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 23/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class CheckinCell: UITableViewCell {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!

    var checkin:Checkin? {
        didSet {
            nameLabel.text = checkin?.place?.name
            dateLabel.text = checkin?.timeAgo()
        }
    }
}