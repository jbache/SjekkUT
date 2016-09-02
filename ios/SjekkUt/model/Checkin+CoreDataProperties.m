//
//  Checkin+CoreDataProperties.m
//  SjekkUt
//
//  Created by Henrik Hartz on 02/09/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Checkin+CoreDataProperties.h"

@implementation Checkin (CoreDataProperties)

@dynamic date;
@dynamic identifier;
@dynamic latitute;
@dynamic longitude;
@dynamic url;
@dynamic isOffline;
@dynamic isPublic;
@dynamic place;
@dynamic user;

@end
