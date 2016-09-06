//
//  CheckinPanel.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 02/09/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class CheckinPanel: UIView, CheckinButtonDelegate {

    @IBOutlet var panelContainer: UIView!
    @IBOutlet var panelView: UIView!
    @IBOutlet var checkinButton: CheckinButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var panelInset: NSLayoutConstraint!
    var hideTimer:NSTimer?

    var showingPanel:Bool = true {
        didSet {
            updatePanelVisibility()
        }
    }

    override func awakeFromNib() {
        panelView.layer.cornerRadius = 5
        panelView.clipsToBounds = true
        panelInset.constant = panelContainer.bounds.size.width
        checkinButton.delegate = self
        panelView.alpha = 0
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        showingPanel = false
    }

    func updatePanelVisibility() {
        panelInset.constant = showingPanel ? 0 : panelContainer.bounds.size.width
        UIView.animateWithDuration(kSjekkUtConstantAnimationDuration) {
            self.layoutIfNeeded()
            self.panelView.alpha = self.showingPanel ? 1 : 0
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let maskPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 5)
        let circleFrame = CGRectInset(  checkinButton.frame, -5, -5)
        let circleOffsetFrame = CGRectOffset(circleFrame, -panelContainer.frame.origin.x, -panelContainer.frame.origin.y)
        maskPath.appendPath(UIBezierPath(ovalInRect:circleOffsetFrame))
        maskPath.usesEvenOddFillRule = true

        let cutCircle = CAShapeLayer()
        cutCircle.path = maskPath.CGPath
        cutCircle.fillColor = UIColor.blackColor().CGColor
        cutCircle.fillRule = kCAFillRuleEvenOdd
        panelView.layer.mask = cutCircle

        updatePanelVisibility()
    }

    func togglePanel() {
        showingPanel = !showingPanel
    }

    @IBAction func hidePanelClicked(sender: AnyObject) {
        showingPanel = false
        hideTimer?.invalidate()
    }

    // prevent clicks on top of the message view being eaten if it's not showing
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return checkinButton.pointInside(convertPoint(point, toView: checkinButton), withEvent: event) || (showingPanel && super.pointInside(point, withEvent: event))
    }

    // MARK: checkin delegate
    func showInfo(aMessage:CheckinMessage) {
        titleLabel.text = aMessage.title
        messageLabel.text = aMessage.message
        showingPanel = true
        hideTimer = NSTimer.scheduledTimerWithTimeInterval(7, target: self, selector: #selector(hideInfo), userInfo: nil, repeats: false)
    }

    func hideInfo() {
        hideTimer?.invalidate()
        showingPanel = false
    }
}