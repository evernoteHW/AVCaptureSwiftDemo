//
//  Test.h
//  SwiftProjectsExample
//
//  Created by WeiHu on 16/5/27.
//  Copyright © 2016年 WeiHu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIUtils : NSObject

+ (NSData *)dataWithBytes;

+ (NSArray *)parseEvents:(NSString *)events;
+ (NSArray *)parseDialogue:(NSString *)dialogue
                 numFields:(NSUInteger)numFields;
+ (NSString *)removeCommandsFromEventText:(NSString *)text;
+ (BOOL) isNetworkPath: (NSString *) path;

@end
