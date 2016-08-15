//
//  DntImageSize+CoreDataProperties.h
//  SjekkUt
//
//  Created by Henrik Hartz on 15/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DntImageSize.h"

NS_ASSUME_NONNULL_BEGIN

@interface DntImageSize (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *width;
@property (nullable, nonatomic, retain) NSNumber *height;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) NSString *etag;
@property (nullable, nonatomic, retain) DntImage *image;

@end

NS_ASSUME_NONNULL_END
