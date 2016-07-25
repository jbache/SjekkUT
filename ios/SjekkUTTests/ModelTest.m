#import "Backend.h"
#import "Checkin+Extension.h"
#import "Kiwi.h"
#import "Location.h"
#import "Summit+Extension.h"

SPEC_BEGIN(ModelTest)

describe(@"Model", ^{
    it(@"should get some summits", ^{
        [backend updateSummits];
        NSUInteger summitCount = [backend summits].count;
        [[theValue(summitCount) shouldEventually] beGreaterThan:theValue(0)];
    });
});

SPEC_END

SPEC_BEGIN(SummitTest)

describe(@"Summit", ^{
    Summit *sut = [Summit mock];

    beforeAll(^{
        [locationBackend getSingleUpdate:nil];
    });

    it(@"Has an identifier", ^{
        [[sut.identifier should] beGreaterThan:theValue(0)];
    });

    it(@"Has a title", ^{
        [[theValue(sut.name.length) should] beGreaterThan:theValue(0)];
    });

    it(@"Has a description", ^{
        [[theValue(sut.description.length) should] beGreaterThan:theValue(0)];
    });

    it(@"Has a county name", ^{
        [[theValue(sut.countyName.length) should] beGreaterThan:theValue(0)];
    });

    it(@"Has latitude within bounds", ^{
        [[sut.latitude should] beBetween:theValue(-90) and:theValue(90)];
    });

    it(@"Has longitude within bounds", ^{
        [[sut.latitude should] beBetween:theValue(-180) and:theValue(180)];
    });

    it(@"Has a valid distance", ^{
        [[sut.distance shouldEventually] beGreaterThanOrEqualTo:theValue(0)];
    });

    it(@"Has a valid elevation", ^{
        [[sut.elevation should] beGreaterThan:theValue(0)];
    });
});

SPEC_END

SPEC_BEGIN(CheckinTest)

describe(@"Checkin", ^{

         });

SPEC_END
