//
//  FSPointData.m
//  Invia
//
//  Created by Lukasz Margielewski on 12/02/16.
//
//

#import "FSPointData.h"

@implementation FSPointData

@synthesize count = _count;
@synthesize points = _points;

- (void)dealloc{free(_points);}
- (instancetype)initWithPointCount:(NSUInteger)pointCount
{
    NSAssert(pointCount > 0, @"pointCount must not be 0.");
    
    self = [super init];
    
    if (self) {
        
        _points = malloc(sizeof(CGPoint) * pointCount);
        _count = pointCount;
    }
    return self;
}
@end
