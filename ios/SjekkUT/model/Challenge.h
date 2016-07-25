//
//  Challenge.h
//  SjekkUt
//
//  Created by Henrik Hartz on 20/05/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "EntityScaffold.h"

@class Summit;

@interface Challenge : EntityScaffold

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSDate *validTo;
@property (nonatomic, retain) NSDate *validFrom;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *logoUrl;
@property (nonatomic, retain) NSString *footerUrl;
@property (nonatomic, retain) NSString *infoUrl;
@property (nonatomic, retain) NSNumber *participating;
@property (nonatomic, retain) NSNumber *userProgress;
@property (nonatomic, retain) NSSet *summits;
@end

@interface Challenge (CoreDataGeneratedAccessors)

- (void)addSummitsObject:(Summit *)value;
- (void)removeSummitsObject:(Summit *)value;
- (void)addSummits:(NSSet *)values;
- (void)removeSummits:(NSSet *)values;

@end
