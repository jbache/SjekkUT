//
//  PlaceCell.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation


class PlaceCell: UITableViewCell {

    var isObserving = false
    var kObserveDistance = 0

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var climbCountLabel: UILabel!
    @IBOutlet weak var countyElevationLabel: UILabel!
    @IBOutlet weak var placeImageView: UIImageView!

    var place:Place? {
        didSet {
            stopObserving()
            nameLabel.text = place?.name
            startObserving()
        }
    }

    deinit {
        stopObserving()
    }

    override func prepareForReuse() {
        stopObserving()
    }

    // MARK: observing

    func startObserving() {
        if (isObserving == false) {
            self.place?.addObserver(self, forKeyPath: "distance", options: .Initial, context: &kObserveDistance)
            isObserving = true
        }
    }

    func stopObserving() {
        if (isObserving == true) {
            self.place?.removeObserver(self, forKeyPath: "distance")
            isObserving = false
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (context == &kObserveDistance) {
            self.distanceLabel.text = self.place?.distanceDescription()
        }
    }
}