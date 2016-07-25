#import <Kiwi/Kiwi.h>

#import "Backend.h"
#import "Location.h"

SPEC_BEGIN(BackendTest)

describe(@"Backend", ^{

    beforeAll(^{
        [locationBackend getSingleUpdate:nil];
    });

    it(@"has a non-nil global instance", ^{
        [backend shouldNotBeNil];
    });

    it(@"has fetch summit API", ^{
        [backend respondsToSelector:@selector(updateSummits)];
    });

    it(@"has a list summits API", ^{
        [backend respondsToSelector:@selector(summits)];
    });

    it(@"receives at least one summit after updating", ^{
        [backend updateSummits];
        [[backend.summits shouldEventually] haveCountOfAtLeast:1];
    });

    it(@"can find the nearest summit", ^{
        Summit *nearest = [backend findNearest:CLLocationCoordinate2DMake(0, 0)];
        [nearest shouldNotBeNil];
    });

    //  it(@"can find the correct nearest summit", ^{
    //
    //    [[locationBackend.currentLocation shouldEventually] beNonNil];
    //
    //    NSMutableArray *summits = [[backend summits] mutableCopy];
    //    for (Summit *smt in summits) {
    //      [smt updateDistance];
    //    }
    //    [summits sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:YES] ]];
    //    Summit *nearest = [summits firstObject];
    //    [summits removeObject:nearest];
    //    [nearest shouldNotBeNil];
    //
    //    for (Summit *summit in summits) {
    //      [[summit.distance should] beGreaterThan:nearest.distance];
    //    }
    //  });

});

SPEC_END
