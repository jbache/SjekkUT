//
//  DntImageSize.h
//  SjekkUt
//
//  Created by Henrik Hartz on 15/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class DntImage;

#import "EntityScaffold.h"

NS_ASSUME_NONNULL_BEGIN

@interface DntImageSize : EntityScaffold

+ (instancetype)insertOrUpdate:(NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END

#import "DntImageSize+CoreDataProperties.h"
