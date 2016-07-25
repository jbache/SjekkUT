#import "Backend.h"
#import "Kiwi.h"
#import "NetworkController.h"
#import "Summit+Extension.h"

SPEC_BEGIN(NetworkTest)

describe(@"Network", ^{
    //  Summit *sut = [Summit mock];

    it(@"has a global instance", ^{
        [backend shouldNotBeNil];
    });

    it(@"has update summit endpoint", ^{
        [backend respondsToSelector:@selector(updateSummits)];
    });

    it(@"has update checkins endpoint", ^{
        [backend respondsToSelector:@selector(updateCheckins)];
    });

    it(@"has checkin endpoint", ^{
        [network respondsToSelector:@selector(checkinTo:and:or:)];
    });

#if 0 // UNSTABLE TEST
  it(@"receives summits", ^{
    NSURLSessionDataTask* task = [backend updateSummits];
    [[expectFutureValue(theValue(task.state)) shouldEventually] equal:theValue(NSURLSessionTaskStateCompleted)];
    [[expectFutureValue(task.error) shouldEventually] beNil];
  });
#endif
});

SPEC_END
