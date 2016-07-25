//
//  PlaceCell.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class PlaceCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!

    var place:Place? {
        didSet {
            self.nameLabel.text = self.place?.name
        }
    }
}