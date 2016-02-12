//
//  FSPointData.h
//  Invia
//
//  Created by Lukasz Margielewski on 12/02/16.
//
//

#import <Foundation/Foundation.h>

@interface FSPointData : NSObject

@property (nonatomic, readonly) CGPoint *points;
@property (nonatomic, readonly) NSUInteger count;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPointCount:(NSUInteger)pointCount NS_DESIGNATED_INITIALIZER;

@end
