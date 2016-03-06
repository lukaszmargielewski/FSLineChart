//
//  FSLinePlot.h
//  Invia
//
//  Created by Lukasz Margielewski on 12/02/16.
//
//

#import <Foundation/Foundation.h>
#import "FSPointData.h"

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
@property (nonatomic) CGFloat dataPointLineWidth;
// Smoothing
@property (nonatomic) BOOL bezierSmoothing;
@property (nonatomic) CGFloat bezierSmoothingTension;

@property (nonatomic, strong, readwrite) FSPointData *data;

@end