//
//  TestLoginView.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 26/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import XCTest

class TestDntApi: XCTestCase {

    var sut:DntApi?

    // Put setup code here. This method is called before the invocation of each test method in the class.
    override func setUp() {
        super.setUp()
        sut = DntApi(forDomain:"www.dnt.no")
    }
    
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    override func tearDown() {
        super.tearDown()
        sut = nil
    }
    
    func testCredentials() {
        XCTAssertTrue(!(sut?.clientId?.isEmpty)!, "client id should not be empty")
        XCTAssertTrue(!(sut?.clientSecret?.isEmpty)!, "client secret should not be empty")
    }

    func testExpiry() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(kSjekkUtDefaultsTokenExpiry)
        XCTAssertFalse((sut?.isExpired)!, "token should not be expired")

        NSUserDefaults.standardUserDefaults().setObject(NSDate().dateByAddingTimeInterval(-3600), forKey: kSjekkUtDefaultsTokenExpiry)
        XCTAssertTrue((sut?.isExpired)!, "token should be expired")
        NSUserDefaults.standardUserDefaults().setObject(NSDate().dateByAddingTimeInterval(3600), forKey: kSjekkUtDefaultsTokenExpiry)
        XCTAssertFalse((sut?.isExpired)!, "token should not be expired")
    }

    func testAuthorizeRequest() {
        let anAuthorizationRequest = sut?.authorizeRequest()
        XCTAssertNotNil(anAuthorizationRequest, "authorization request should not be nil")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
