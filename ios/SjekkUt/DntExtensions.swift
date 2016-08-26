//
//  DntExtensionsString.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 02/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

extension NSDate {

    @objc func timeAgo() -> String {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Short
        formatter.includesApproximationPhrase = false
        formatter.includesTimeRemainingPhrase = false
        formatter.maximumUnitCount = 1
        formatter.allowedUnits = [.Minute, .Hour, .Day, .WeekOfMonth, .Month, .Year]
        let dateRelativeString = formatter.stringFromDate(self, toDate: NSDate())
        return dateRelativeString!
    }
}

extension String {
    func loadFileContents(inClass aClass:AnyClass) -> String? {
        let fileURL = NSBundle(forClass: aClass).URLForResource(self, withExtension: nil, subdirectory: nil)
        var fileContents:String?
        do {
            try fileContents = NSString(contentsOfURL: fileURL!, encoding: NSUTF8StringEncoding) as String
            fileContents = fileContents!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
        catch {
            print("failed to load file %@: %@", self, error)
        }
        return fileContents
    }

    func URL() -> NSURL? {
        return NSURL(string:self)
    }
}

extension NSString {
    @objc func loadFileContents(inClass aClass:AnyClass) -> String? {
        let aString = self as String
        return aString.loadFileContents(inClass: aClass)
    }
}

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

extension Place {
    func countyElevationText() -> String {
        var countyElevationTexts = [String]()
        if let countyText = self.county {
            countyElevationTexts.append(countyText)
        }
        if let elevationText:String = self.elevationDescription() {
            countyElevationTexts.append(elevationText)
        }
        return countyElevationTexts.joinWithSeparator(" ")
    }
}