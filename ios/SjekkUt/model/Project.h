//
//  Project.h
//
//
//  Created by Henrik Hartz on 26/07/16.
//
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "EntityScaffold.h"

NS_ASSUME_NONNULL_BEGIN

@interface Project : EntityScaffold

+ (NSFetchRequest *)fetchRequest;
+ (instancetype)insertOrUpdate:(NSDictionary *)json;

- (void)updateDistance;

@end

NS_ASSUME_NONNULL_END

#import "Project+CoreDataProperties.h"
