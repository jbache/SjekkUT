//
//  JoinProjectCell.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 29/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class JoinProjectCell: UITableViewCell {

    var project:Project? = nil

    @IBAction func joinProjectClicked(sender: AnyObject) {
        SjekkUtApi.instance.doJoinProject(project!)
    }
}