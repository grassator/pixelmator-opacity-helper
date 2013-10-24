//
//  DKOpacityController.h
//  Pixelmator Opacity Helper
//
//  Created by Dmitriy Kubyshkin on 10/24/13.
//  Copyright (c) 2013 Dmitriy Kubyshkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DKOpacityController : NSObject

@property (readwrite) id eventHandler;
@property (readwrite) NSDate *lastTimePressed;
@property (nonatomic, assign) NSInteger lastValue;

@end
