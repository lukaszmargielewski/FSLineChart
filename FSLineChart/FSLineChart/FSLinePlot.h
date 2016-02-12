//
//  FSLinePlot.h
//  Invia
//
//  Created by Lukasz Margielewski on 12/02/16.
//
//

#import <Foundation/Foundation.h>


@interface FSLinePlot : NSObject

@property (nonatomic, strong) NSString* name;
// Chart parameters
@property (nonatomic, strong) UIColor* color;
@property (nonatomic, strong) UIColor* fillColor;
@property (nonatomic) CGFloat lineWidth;

// Data points
@property (nonatomic) BOOL displayDataPoint;
@property (nonatomic, strong) UIColor* dataPointColor;
@property (nonatomic, strong) UIColor* dataPointBackgroundColor;
@property (nonatomic) CGFloat dataPointRadius;

// Smoothing
@property (nonatomic) BOOL bezierSmoothing;
@property (nonatomic) CGFloat bezierSmoothingTension;

@property (nonatomic, strong, readonly) NSArray *data;

- (void)setChartData:(NSArray *)data;

@end