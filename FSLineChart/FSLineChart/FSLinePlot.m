//
//  FSLinePlot.m
//  Invia
//
//  Created by Lukasz Margielewski on 12/02/16.
//
//

#import "FSLinePlot.h"

@interface FSLinePlot()
@end

@implementation FSLinePlot{
    
}

#pragma mark - Initialisation

- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    [self setDefaultParameters];
}
- (void)setDefaultParameters
{
    _color = [UIColor blueColor];
    _fillColor = [_color colorWithAlphaComponent:0.25];
    _bezierSmoothing = YES;
    _bezierSmoothingTension = 0.2;
    _lineWidth = 1;
    _dataPointLineWidth = 1;
    _displayDataPoint = NO;
    _dataPointRadius = 1;
    _dataPointColor = _color;
    _dataPointBackgroundColor = _color;
    
}
@end
