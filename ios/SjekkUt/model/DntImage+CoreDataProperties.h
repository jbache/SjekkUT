//
//  DntImage+CoreDataProperties.h
//  SjekkUt
//
//  Created by Henrik Hartz on 03/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DntImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface DntImage (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) NSNumber *width;
@property (nullable, nonatomic, retain) NSNumber *height;
@property (nullable, nonatomic, retain) NSData *data;
@property (nullable, nonatomic, retain) Project *projects;

@end

NS_ASSUME_NONNULL_END
