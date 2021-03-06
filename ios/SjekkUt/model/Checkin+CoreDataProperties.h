//
//  Checkin+CoreDataProperties.h
//  SjekkUt
//
//  Created by Henrik Hartz on 02/09/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Checkin.h"

NS_ASSUME_NONNULL_BEGIN

@interface Checkin (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *date;
@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) NSNumber *latitute;
@property (nullable, nonatomic, retain) NSNumber *longitude;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) NSNumber *isOffline;
@property (nullable, nonatomic, retain) NSNumber *isPublic;
@property (nullable, nonatomic, retain) Place *place;
@property (nullable, nonatomic, retain) DntUser *user;

@end

NS_ASSUME_NONNULL_END
