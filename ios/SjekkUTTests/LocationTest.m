#import "Backend.h"
#import "Kiwi.h"
#import "Location.h"

SPEC_BEGIN(LocationTest)

describe(@"Location", ^{
    beforeAll(^{
        [locationBackend checkPermissions:^{
            [locationBackend getSingleUpdate:nil];
        }];
    });

    it(@"should get a valid coordinate", ^{
        [[locationBackend.currentLocation shouldEventually] beNonNil];
    });
});

SPEC_END
