//
//  ProjectCell.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 26/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class ProjectCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!

    var project:Project? {
        didSet {
            self.nameLabel.text = project?.name
        }
    }
}