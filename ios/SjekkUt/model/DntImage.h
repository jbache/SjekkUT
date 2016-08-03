//
//  DntImage.h
//  SjekkUt
//
//  Created by Henrik Hartz on 03/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "EntityScaffold.h"

@class Project;

NS_ASSUME_NONNULL_BEGIN

@interface DntImage : EntityScaffold

+ (instancetype)insertOrUpdate:(NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END

#import "DntImage+CoreDataProperties.h"
