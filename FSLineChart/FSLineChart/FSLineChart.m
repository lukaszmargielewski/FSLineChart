//
//  FSLineChart.m
//  FSLineChart
//
//  Created by Arthur GUIBERT on 30/09/2014.
//  Copyright (c) 2014 Arthur GUIBERT. All rights reserved.
//
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <QuartzCore/QuartzCore.h>
#import "FSLineChart.h"

#define FSTX(xxx) ((xxx) * _xScale - _visibleRegion.origin.x)
#define FSTY(yyy) ((_axisHeight - (yyy) * _yScale) - _visibleRegion.origin.y)

#define FSTX_MARGIN(xxx) (FSTX(xxx) + _margin.left)
#define FSTY_MARGIN(yyy) (FSTY(yyy) + _margin.top)


@interface FSLineChart ()
@property (nonatomic, strong) NSMutableArray* plots;
@property (nonatomic, strong) NSMutableArray* layers;

@property (nonatomic) CGMutablePathRef initialPath;
@property (nonatomic) CGMutablePathRef newPath;
@property (nonatomic, strong) CALayer *graphLayer;

@end

@implementation FSLineChart{

    NSInteger _maxCount;
    
    CGFloat _xScale;
    CGFloat _yScale;
    
    CGFloat _axisWidth;
    CGFloat _axisHeight;
    CGRect _graphFrame;
}

#pragma mark - Initialisation

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _layers = [NSMutableArray array];
    _plots = [NSMutableArray array];
    _visibleRegion = CGRectMake(0, 0, 1, 1);
    self.graphLayer = [CALayer layer];
    self.graphLayer.contentsGravity = kCAGravityTopLeft;
    [self.layer addSublayer:self.graphLayer];
    
    self.backgroundColor = [UIColor whiteColor];
    [self setDefaultParameters];
}

- (void)setDefaultParameters
{
    _verticalGridStep = 1;
    _horizontalGridStep = 1;
    _margin = UIEdgeInsetsMake(5, 5, 5, 5);
    _axisColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    _innerGridColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    _drawInnerGrid = YES;
    _innerGridLineWidth = 0.5;
    _axisLineWidth = 1;
    _animationDuration = 0.5;
    // Labels attributes
    _indexLabelBackgroundColor = [UIColor clearColor];
    _indexLabelTextColor = [UIColor grayColor];
    _indexLabelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:10];
    
    _valueLabelBackgroundColor = [UIColor colorWithWhite:1 alpha:0.75];
    _valueLabelTextColor = [UIColor grayColor];
    _valueLabelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:11];
    _valueLabelPosition = ValueLabelRight;

    [self recalculateAxisAndScales];
    [self layoutChartLayer];
}

- (void)layoutSubviews
{
    
    // Removing the old label views as well as the chart layers.
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    
    [self.layers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CALayer* layer = (CALayer*)obj;
        [layer removeFromSuperlayer];
    }];
    
    [self recalculateAxisAndScales];
    [self layoutChartLayer];
    [self reloadPlots];
    
    [super layoutSubviews];
}
- (void)setMargin:(UIEdgeInsets)margin{

    _margin = margin;
    [self recalculateAxisAndScales];
    [self layoutChartLayer];
}
- (void)setVisibleRegion:(CGRect)visibleRegion{

    _visibleRegion = visibleRegion;
    [self recalculateAxisAndScales];
    
}
- (void)addPlot:(FSLinePlot *)plot
{
    [self.plots addObject:plot];
    
    _maxCount = 0;
    
    for (FSLinePlot *plot in self.plots) {
        _maxCount = MAX(_maxCount, plot.data.count);
    }
    
}

- (void)clearAllPlots
{

    [self.plots removeAllObjects];
    [self reloadPlots];
}

- (void)recalculateAxisAndScales{

    _graphFrame = self.layer.bounds;
    _graphFrame.origin.x += _margin.left;
    _graphFrame.origin.y += _margin.top;
    
    _graphFrame.size.width -= (_margin.left + _margin.right);
    _graphFrame.size.height -= (_margin.top + _margin.bottom);
    
    _axisWidth = _graphFrame.size.width;
    _axisHeight = _graphFrame.size.height;
    
    _xScale = _axisWidth / _visibleRegion.size.width;
    _yScale = _axisHeight / _visibleRegion.size.height;
    
}
- (void)layoutChartLayer{

    self.graphLayer.frame = _graphFrame;
}
- (void)reloadPlots
{
    
    [self clearChartData];
    if(self.plots == nil || self.plots.count < 1) {
        return;
    }
    
    [self strokeChart];
    
    for (FSLinePlot *plot in self.plots) {

        if(plot.displayDataPoint) {
            [self strokeDataPointsForPlot:plot];
        }

    }
    
    CGFloat minYBound = [self minVerticalBound];
    CGFloat maxYBound = [self maxVerticalBound];
    CGFloat minXBound = [self minHorizontalBound];
    CGFloat maxXBound = [self maxHorizontalBound];
    
    if(_labelForYValue) {
        for(CGFloat y = minYBound; y <= maxYBound; y += _verticalGridStep) {
            
            UILabel* label = [self createLabelForYValue:y];
            
            if(label) {
                [self addSubview:label];
            }
        }
    }
    
    if(_iconForYValue) {
        
        for(CGFloat y = minYBound; y <= maxYBound; y += _verticalGridStep) {
            
            UIImageView* iconView = [self createIconForYValue:y];
            
            if(iconView) {
                [self addSubview:iconView];
            }
        }
    }
    
    if(_labelForXValue) {
        
        for(CGFloat x = minXBound; x <= maxXBound; x += _horizontalGridStep) {
            
            UILabel* label = [self createLabelForXValue:x];
            
            if(label) {
                [self addSubview:label];
            }
        }
    }
    
    [self setNeedsDisplay];
}

#pragma mark - Labels creation

- (UILabel*)createLabelForYValue: (CGFloat)y
{

    NSString* text = _labelForYValue(y);
    CGFloat x = _margin.left + (_valueLabelPosition == ValueLabelRight ? _axisWidth : 0);

    
    if(!text)
    {
        return nil;
    }
    y = FSTY_MARGIN(y) + 2;
    
    CGRect rect = CGRectMake(_margin.left, y, _axisWidth - 4.0f, 14);
    
    float width = [text boundingRectWithSize:rect.size
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{ NSFontAttributeName:_valueLabelFont }
                                     context:nil].size.width;
    
    CGFloat xPadding = 6;
    CGFloat xOffset = width + xPadding;
    
    if (_valueLabelPosition == ValueLabelLeftMirrored) {
        xOffset = -xPadding;
    }
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(x - xOffset, y, width + 2, 14)];
    label.text = text;
    label.font = _valueLabelFont;
    label.textColor = _valueLabelTextColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = _valueLabelBackgroundColor;
    
    return label;
}

- (UIImageView*)createIconForYValue:(CGFloat)y
{
    CGFloat x = _margin.left + (_valueLabelPosition == ValueLabelRight ? _axisWidth : 0);
    
    UIImage* icon = _iconForYValue(y);
    
    if(!icon)
    {
        return nil;
    }
    
    CGFloat width = icon.size.width;
    CGFloat height = icon.size.height;
    
    CGFloat xPadding = 6;
    CGFloat xOffset = width + xPadding;
    
    if (_valueLabelPosition == ValueLabelLeftMirrored) {
        xOffset = -xPadding;
    }
    
    y = FSTY_MARGIN(y) + 2;
    
    UIImageView* iconView = [[UIImageView alloc] initWithFrame:CGRectMake(x - xOffset, y, width + 2, height + 2)];
    iconView.clipsToBounds = NO;
    iconView.contentMode = UIViewContentModeCenter;
    iconView.image = icon;
    iconView.backgroundColor = _valueIconBackgroundColor;
    
    return iconView;
}

- (UILabel*)createLabelForXValue:(CGFloat)x
{

    
    NSString* text = _labelForXValue(x);
    
    if(!text)
    {
        return nil;
    }
    
    CGFloat y = _axisHeight + _margin.top + 2;
    
    x = FSTX_MARGIN(x);
    
    CGRect rect = CGRectMake(x + 2, y, _axisWidth - 4.0f, 14);
    
    float width = [text boundingRectWithSize:rect.size
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{ NSFontAttributeName:_indexLabelFont }
                                     context:nil].size.width;
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(x - 4.0f, y, width + 2, 14)];
    label.text = text;
    label.font = _indexLabelFont;
    label.textColor = _indexLabelTextColor;
    label.backgroundColor = _indexLabelBackgroundColor;
    
    return label;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    if (self.plots.count > 0) {
        [self drawGrid];
    }
}

- (void)drawGrid
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(ctx);
    CGContextSetLineWidth(ctx, _axisLineWidth);
    CGContextSetStrokeColorWithColor(ctx, [_axisColor CGColor]);
    
    // draw coordinate axis
    CGContextMoveToPoint(ctx, _margin.left, _margin.top);
    CGContextAddLineToPoint(ctx, _margin.left, _axisHeight + _margin.top + 3);
    CGContextStrokePath(ctx);
    
    CGFloat minYBound = [self minVerticalBound];
    CGFloat maxYBound = [self maxVerticalBound];
    CGFloat minXBound = [self minHorizontalBound];
    CGFloat maxXBound = [self maxHorizontalBound];
    
    // draw grid
    if(_drawInnerGrid) {
        
        CGFloat y0  = _margin.top;
        CGFloat y1  = _axisHeight + _margin.top;
        
        for(CGFloat xG = minXBound; xG <= maxXBound; xG += _horizontalGridStep) {
            
            CGFloat x = FSTX_MARGIN(xG);
            
            
            CGContextSetStrokeColorWithColor(ctx, [_innerGridColor CGColor]);
            CGContextSetLineWidth(ctx, _innerGridLineWidth);
            
            // x grid:
            CGContextMoveToPoint(   ctx, x, y0);
            CGContextAddLineToPoint(ctx, x, y1);
            CGContextStrokePath(ctx);
            
            CGContextSetStrokeColorWithColor(ctx, [_axisColor CGColor]);
            CGContextSetLineWidth(ctx, _axisLineWidth);
            
            // x axis marks:
            CGContextMoveToPoint(   ctx, x - 0.5f, _axisHeight + _margin.top);
            CGContextAddLineToPoint(ctx, x - 0.5f, _axisHeight + _margin.top + 3);
            CGContextStrokePath(ctx);
        }
        
        CGFloat x0 = _margin.left;
        CGFloat x1 = _axisWidth + _margin.left;
        
        for(CGFloat yG = minYBound; yG <= maxYBound; yG += _verticalGridStep) {
            
            CGFloat y = FSTY_MARGIN(yG);
            
            if(y == 0) {
                CGContextSetLineWidth(ctx, _axisLineWidth);
                CGContextSetStrokeColorWithColor(ctx, [_axisColor CGColor]);
            } else {
                CGContextSetStrokeColorWithColor(ctx, [_innerGridColor CGColor]);
                CGContextSetLineWidth(ctx, _innerGridLineWidth);
            }
            
            CGContextMoveToPoint(   ctx, x0, y);
            CGContextAddLineToPoint(ctx, x1, y);
            
            CGContextStrokePath(ctx);
        }
    }
    
}

- (void)clearChartData
{
    for (CAShapeLayer *layer in self.layers) {
        [layer removeFromSuperlayer];
    }
    [self.layers removeAllObjects];
}

- (void)strokeChart
{
    CGRect frame = self.graphLayer.bounds;
    
    for (FSLinePlot *plot in self.plots) {
        
        FSPointData *data       = plot.data;
        
        if (plot.data.count < 1) {
            continue;
        }
        CGFloat     tension     = plot.bezierSmoothingTension;
        BOOL        smoothing   = plot.bezierSmoothing;
        
        UIBezierPath *withPath  = [self bezierPathFromPointData:data xOnly:NO bezierSmoothingTension:tension withSmoothing:smoothing close:NO];
        UIBezierPath *withFill  = [self bezierPathFromPointData:data xOnly:NO bezierSmoothingTension:tension withSmoothing:smoothing close:YES];
        
        if(plot.fillColor) {
            
            CAShapeLayer* fillLayer = [CAShapeLayer layer];
            fillLayer.frame = frame;
            fillLayer.path = withFill.CGPath;
            fillLayer.strokeColor = nil;
            fillLayer.fillColor = plot.fillColor.CGColor;
            fillLayer.lineWidth = 0;
            fillLayer.lineJoin = kCALineJoinRound;
            //fillLayer.borderWidth = 1;
            
            [self.graphLayer addSublayer:fillLayer];
            [self.layers addObject:fillLayer];
            
            UIBezierPath *noFill   = [self bezierPathFromPointData:data xOnly:YES bezierSmoothingTension:tension withSmoothing:smoothing close:YES];
            
            CABasicAnimation *fillAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
            fillAnimation.duration = _animationDuration;
            fillAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            fillAnimation.fillMode = kCAFillModeForwards;
            fillAnimation.fromValue = (id)noFill.CGPath;
            fillAnimation.toValue = (id)withFill.CGPath;
            [fillLayer addAnimation:fillAnimation forKey:@"path"];
        }
        
        CAShapeLayer *pathLayer = [CAShapeLayer layer];
        pathLayer.frame = frame;
        pathLayer.path = withPath.CGPath;
        pathLayer.strokeColor = [plot.color CGColor];
        pathLayer.fillColor = nil;
        pathLayer.lineWidth = plot.lineWidth;
        pathLayer.lineJoin = kCALineJoinRound;
        //pathLayer.borderWidth = 1;
        
        [self.graphLayer addSublayer:pathLayer];
        [self.layers addObject:pathLayer];
        
        if(plot.fillColor) {
            
            UIBezierPath *noPath    = [self bezierPathFromPointData:data xOnly:YES bezierSmoothingTension:tension withSmoothing:smoothing close:NO];
            
            CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
            pathAnimation.duration = _animationDuration;
            pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            pathAnimation.fromValue = (__bridge id)(noPath.CGPath);
            pathAnimation.toValue = (__bridge id)(withPath.CGPath);
            [pathLayer addAnimation:pathAnimation forKey:@"path"];
            
        } else {
            
            CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            pathAnimation.duration = _animationDuration;
            pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
            pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
            [pathLayer addAnimation:pathAnimation forKey:@"path"];
        }

    }
}

- (void)strokeDataPointsForPlot:(FSLinePlot *)plot
{

    FSPointData *data = plot.data;
    CGPoint *points = data.points;
    
    for(int i= 0;i<data.count;i++) {
        
        CGPoint p = [self translateAndScalePoint:points[i]];
        
        UIBezierPath* circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(p.x - plot.dataPointRadius, p.y - plot.dataPointRadius, plot.dataPointRadius * 2, plot.dataPointRadius * 2)];
        
        CAShapeLayer *fillLayer = [CAShapeLayer layer];
        fillLayer.frame = CGRectMake(p.x, p.y, plot.dataPointRadius, plot.dataPointRadius);
        fillLayer.bounds = CGRectMake(p.x, p.y, plot.dataPointRadius, plot.dataPointRadius);
        fillLayer.path = circle.CGPath;
        fillLayer.strokeColor = plot.dataPointColor.CGColor;
        fillLayer.fillColor = plot.dataPointBackgroundColor.CGColor;
        fillLayer.lineWidth = plot.dataPointLineWidth;
        fillLayer.lineJoin = kCALineJoinRound;
        
        [self.graphLayer addSublayer:fillLayer];
        [self.layers addObject:fillLayer];
    }
}

#pragma mark - Chart scale & boundaries


- (CGFloat)minVerticalBound
{
    return ceilf(CGRectGetMinY(_visibleRegion) / _verticalGridStep)  * _verticalGridStep;
}

- (CGFloat)maxVerticalBound
{
    return floorf(CGRectGetMaxY(_visibleRegion) / _verticalGridStep)  * _verticalGridStep;
}

- (CGFloat)minHorizontalBound
{
    return ceilf(CGRectGetMinX(_visibleRegion) / _horizontalGridStep)  * _horizontalGridStep;
}

- (CGFloat)maxHorizontalBound
{
    return floorf(CGRectGetMaxX(_visibleRegion) / _horizontalGridStep)  * _horizontalGridStep;
}

#pragma mark - Chart utils

- (CGPoint)translateAndScalePoint:(CGPoint)point{
    
    return CGPointMake(FSTX(point.x), FSTY(point.y));
}

- (UIBezierPath*)bezierPathFromPointData:(FSPointData *)data
                                   xOnly:(BOOL)xOnly
                  bezierSmoothingTension:(CGFloat)bezierSmoothingTension
                           withSmoothing:(BOOL)smoothed
                                   close:(BOOL)closed
{
    UIBezierPath* path = [UIBezierPath bezierPath];
    CGPoint *points = data.points;
    
    
    if(smoothed) {
        
        for(int i=0;i<data.count - 1;i++) {
            
            CGPoint controlPoint[2];
            CGPoint p = [self translateAndScalePoint:points[i]];
            if (xOnly)p.y = _axisHeight;
            
            // Start the path drawing
            if(i == 0)
                [path moveToPoint:p];
            
            CGPoint nextPoint, previousPoint, m;
            
            // First control point
            nextPoint = [self translateAndScalePoint:points[i + 1]];
            if (xOnly)nextPoint.y = _axisHeight;
            previousPoint = [self translateAndScalePoint:points[i - 1]];
            if (xOnly)previousPoint.y = _axisHeight;
            
            m = CGPointZero;
            
            if(i > 0) {
                m.x = (nextPoint.x - previousPoint.x) / 2;
                m.y = (nextPoint.y - previousPoint.y) / 2;
            } else {
                m.x = (nextPoint.x - p.x) / 2;
                m.y = (nextPoint.y - p.y) / 2;
            }
            
            controlPoint[0].x = p.x + m.x * bezierSmoothingTension;
            controlPoint[0].y = p.y + m.y * bezierSmoothingTension;
            
            // Second control point
            nextPoint = [self translateAndScalePoint:points[i + 2]];
            if (xOnly)nextPoint.y = _axisHeight;
            
            previousPoint = [self translateAndScalePoint:points[i]];
            if (xOnly)previousPoint.y = _axisHeight;
            
            p = [self translateAndScalePoint:points[i + 1]];
            if (xOnly)p.y = _axisHeight;
            
            m = CGPointZero;
            
            if(i < data.count - 2) {
                m.x = (nextPoint.x - previousPoint.x) / 2;
                m.y = (nextPoint.y - previousPoint.y) / 2;
            } else {
                m.x = (p.x - previousPoint.x) / 2;
                m.y = (p.y - previousPoint.y) / 2;
            }
            
            controlPoint[1].x = p.x - m.x * bezierSmoothingTension;
            controlPoint[1].y = p.y - m.y * bezierSmoothingTension;
            
            [path addCurveToPoint:p controlPoint1:controlPoint[0] controlPoint2:controlPoint[1]];
        }
        
    } else {
        
        for(int i=0;i<data.count;i++) {
            
            if(i > 0) {
                
                CGPoint p = [self translateAndScalePoint:points[i]];
                if (xOnly)p.y = _axisHeight;
                [path addLineToPoint:p];
                
            } else {
                
                CGPoint p = [self translateAndScalePoint:points[i]];
                if (xOnly)p.y = _axisHeight;
                
                [path moveToPoint:p];
            }
        }
    }
    
    if(closed) {
        
        CGPoint p = [self translateAndScalePoint:points[data.count - 1]];
        if (xOnly)p.y = _axisHeight;
        
        // Closing the path for the fill drawing
        [path addLineToPoint:p];
        
        p = [self translateAndScalePoint:points[data.count - 1]];
        p.y = _axisHeight;
        [path addLineToPoint:p];
        p = [self translateAndScalePoint:points[0]];
        p.y = _axisHeight;
        [path addLineToPoint:p];
        
        p = [self translateAndScalePoint:points[0]];
        if (xOnly)p.y = _axisHeight;
        [path addLineToPoint:p];
    }
    
    return path;
}


@end
