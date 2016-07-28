//
//  Place+CoreDataProperties.m
//  SjekkUt
//
//  Created by Henrik Hartz on 28/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Place+CoreDataProperties.h"

@implementation Place (CoreDataProperties)

@dynamic identifier;
@dynamic name;
@dynamic latitude;
@dynamic longitude;
@dynamic elevation;
@dynamic distance;
@dynamic projects;

@end
