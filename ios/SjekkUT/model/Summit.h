//
//  Summit.h
//  SjekkUt
//
//  Created by Henrik Hartz on 09/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "EntityScaffold.h"
@class Challenge, Checkin, CheckinStatistics, Comment;

@interface Summit : EntityScaffold

@property (nonatomic, retain) NSNumber *checkinCount;
@property (nonatomic, retain) NSString *countyName;
@property (nonatomic, retain) NSNumber *distance;
@property (nonatomic, retain) NSNumber *elevation;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *imageUrl;
@property (nonatomic, retain) NSString *information;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *typeName;
@property (nonatomic, retain) NSString *infoUrl;
@property (nonatomic, retain) NSNumber *hidden;
@property (nonatomic, retain) NSSet *checkins;
@property (nonatomic, retain) Comment *comments;
@property (nonatomic, retain) CheckinStatistics *statistics;
@property (nonatomic, retain) Challenge *challenge;
@end

@interface Summit (CoreDataGeneratedAccessors)

- (void)addCheckinsObject:(Checkin *)value;
- (void)removeCheckinsObject:(Checkin *)value;
- (void)addCheckins:(NSSet *)values;
- (void)removeCheckins:(NSSet *)values;

@end
