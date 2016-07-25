//
//  Comment.h
//
//
//  Created by Henrik Hartz on 24/04/15.
//
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class Summit;

@interface Comment : NSManagedObject

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) Summit *summit;

@end
