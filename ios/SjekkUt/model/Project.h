//
//  Project.h
//
//
//  Created by Henrik Hartz on 26/07/16.
//
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "DntImage.h"
#import "EntityScaffold.h"
#import "Place.h"

NS_ASSUME_NONNULL_BEGIN

@interface Project : EntityScaffold

+ (NSFetchRequest *)fetchRequest;
+ (instancetype)insertOrUpdate:(NSDictionary *)json;

- (void)updateDistance;
- (void)updateHasCheckin;
- (Place *)findNearest;
- (NSString *)progressDescriptionLong;
- (NSString *)progressDescriptionShort;
- (NSURL *)backgroundImageURLforSize:(CGSize)aSize;
- (NSURL *)foregroundImageURLforSize:(CGSize)aSize;

@end

NS_ASSUME_NONNULL_END

#import "Project+CoreDataProperties.h"
