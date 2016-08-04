//
//  DntExtensionsString.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 02/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

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
}

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}