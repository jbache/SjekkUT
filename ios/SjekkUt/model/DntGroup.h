//
//  DntGroup.h
//  SjekkUt
//
//  Created by Henrik Hartz on 16/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "EntityScaffold.h"

@class Project;

NS_ASSUME_NONNULL_BEGIN

@interface DntGroup : EntityScaffold

+ (instancetype)insertOrUpdate:(NSDictionary *)json;
+ (instancetype)findWithId:(id)identifier;

@end

NS_ASSUME_NONNULL_END

#import "DntGroup+CoreDataProperties.h"
