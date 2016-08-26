//
//  DntImage.h
//  SjekkUt
//
//  Created by Henrik Hartz on 03/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

@import CoreData;
@import CoreGraphics;

#import "DntImageSize.h"
#import "EntityScaffold.h"
#import "Place.h"

@class Project;

NS_ASSUME_NONNULL_BEGIN

@interface DntImage : EntityScaffold

+ (instancetype)insertOrUpdate:(id)json;

- (NSURL *)URLforSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END

#import "DntImage+CoreDataProperties.h"
