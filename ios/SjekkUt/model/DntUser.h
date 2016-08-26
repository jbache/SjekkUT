//
//  DntUser.h
//  SjekkUt
//
//  Created by Henrik Hartz on 23/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import "EntityScaffold.h"
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class Checkin, Project;

NS_ASSUME_NONNULL_BEGIN

@interface DntUser : EntityScaffold

+ (instancetype)currentUser;
+ (void)setCurrentUser:(DntUser *_Nullable)aUser;
+ (instancetype)insertOrUpdate:(NSDictionary *)json;
+ (instancetype)findWithId:(id)identifier;

- (NSString *)fullName;

@end

NS_ASSUME_NONNULL_END

#import "DntUser+CoreDataProperties.h"
