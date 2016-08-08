//
//  ModelController.h
//  SjekkUt
//
//  Created by Henrik Hartz on 04/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#define model [ModelController instance]

@interface NSString (URL)
- (NSURL *)URL;
@end

typedef void (^InitCallbackBlock)(void);

@interface ModelController : NSObject

@property (readonly, strong) NSManagedObjectContext *managedObjectContext;

- (id)initWithCallback:(InitCallbackBlock)callback;
- (void)save;
- (void)delayUntilReady:(void (^)(void))aCallback;

+ (ModelController *)instance;

@end
