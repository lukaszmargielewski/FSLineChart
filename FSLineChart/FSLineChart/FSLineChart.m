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

- (void)awakeFromNib
{
    [self commonInit];
}

- (void)commonInit
{
    _layers = [NSMutableArray array];
    _plots = [NSMutableArray array];
    _visibleRegion = CGRectMake(0, 0, 1, 1);
    _graphLayer = [CALayer layer];
    _graphLayer.contentsGravity = kCAGravityTopLeft;
    [self.layer addSublayer:_graphLayer];
    
    self.backgroundColor = [UIColor whiteColor];
    [self setDefaultParameters];
}

- (void)setDefaultParameters
{
    _verticalGridStep = 3;
    _horizontalGridStep = 3;
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
    [self repositionPlots];
    
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
}

- (void)clearAllPlots
{

    [self.plots removeAllObjects];
    [self repositionPlots];
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

    _graphLayer.frame = _graphFrame;
}
- (void)repositionPlots
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
    
    if(_labelForValue) {
        for(int i=0;i<_verticalGridStep;i++) {
            UILabel* label = [self createLabelForValue:i];
            
            if(label) {
                [self addSubview:label];
            }
        }
    }
    
    if(_iconForValue) {
        for(int i=0;i<_verticalGridStep;i++) {
            UIImageView* iconView = [self createIconForValue:i];
            
            if(iconView) {
                [self addSubview:iconView];
            }
        }
    }
    
    if(_labelForIndex) {
        for(int i=0;i<_horizontalGridStep + 1;i++) {
            UILabel* label = [self createLabelForIndex:i];
            
            if(label) {
                [self addSubview:label];
            }
        }
    }
    
    [self setNeedsDisplay];
}

#pragma mark - Labels creation

- (UILabel*)createLabelForValue: (NSUInteger)index
{
    CGFloat minBound = [self minVerticalBound];
    CGFloat maxBound = [self maxVerticalBound];
    
    CGPoint p = CGPointMake(_margin.left + (_valueLabelPosition == ValueLabelRight ? _axisWidth : 0), _axisHeight + _margin.top - (index + 1) * _axisHeight / _verticalGridStep);
    
    NSString* text = _labelForValue(minBound + (maxBound - minBound) / _verticalGridStep * (index + 1));
    
    if(!text)
    {
        return nil;
    }
    
    CGRect rect = CGRectMake(_margin.left, p.y + 2, _axisWidth - 4.0f, 14);
    
    float width = [text boundingRectWithSize:rect.size
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{ NSFontAttributeName:_valueLabelFont }
                                     context:nil].size.width;
    
    CGFloat xPadding = 6;
    CGFloat xOffset = width + xPadding;
    
    if (_valueLabelPosition == ValueLabelLeftMirrored) {
        xOffset = -xPadding;
    }
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(p.x - xOffset, p.y + 2, width + 2, 14)];
    label.text = text;
    label.font = _valueLabelFont;
    label.textColor = _valueLabelTextColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = _valueLabelBackgroundColor;
    
    return label;
}

- (UIImageView*)createIconForValue: (NSUInteger)index
{
    CGFloat minBound = [self minVerticalBound];
    CGFloat maxBound = [self maxVerticalBound];
    
    CGPoint p = CGPointMake(_margin.left + (_valueLabelPosition == ValueLabelRight ? _axisWidth : 0), _axisHeight + _margin.top - (index + 1) * _axisHeight / _verticalGridStep);
    
    UIImage* icon = _iconForValue(minBound + (maxBound - minBound) / _verticalGridStep * (index + 1));
    
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
    
    UIImageView* iconView = [[UIImageView alloc] initWithFrame:CGRectMake(p.x - xOffset, p.y + 2, width + 2, height + 2)];
    iconView.clipsToBounds = NO;
    iconView.contentMode = UIViewContentModeCenter;
    iconView.image = icon;
    iconView.backgroundColor = _valueIconBackgroundColor;
    
    return iconView;
}

- (UILabel*)createLabelForIndex: (NSUInteger)index
{
    CGFloat scale = [self horizontalScale];
    NSInteger q = (int)_maxCount / _horizontalGridStep;
    NSInteger itemIndex = q * index;
    
    if(itemIndex >= _maxCount)
    {
        itemIndex = _maxCount - 1;
    }
    
    NSString* text = _labelForIndex(itemIndex);
    
    if(!text)
    {
        return nil;
    }
    
    CGPoint p = CGPointMake(_margin.left + index * (_axisWidth / _horizontalGridStep) * scale, _axisHeight + _margin.top);
    
    CGRect rect = CGRectMake(_margin.left, p.y + 2, _axisWidth - 4.0f, 14);
    
    float width = [text boundingRectWithSize:rect.size
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{ NSFontAttributeName:_indexLabelFont }
                                     context:nil].size.width;
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(p.x - 4.0f, p.y + 2, width + 2, 14)];
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
    
    CGFloat scale = [self horizontalScale];
    CGFloat minBound = [self minVerticalBound];
    CGFloat maxBound = [self maxVerticalBound];
    
    // draw grid
    if(_drawInnerGrid) {
        for(int i=0;i<_horizontalGridStep;i++) {
            CGContextSetStrokeColorWithColor(ctx, [_innerGridColor CGColor]);
            CGContextSetLineWidth(ctx, _innerGridLineWidth);
            
            CGPoint point = CGPointMake((1 + i) * _axisWidth / _horizontalGridStep * scale + _margin.left, _margin.top);
            
            CGContextMoveToPoint(ctx, point.x, point.y);
            CGContextAddLineToPoint(ctx, point.x, _axisHeight + _margin.top);
            CGContextStrokePath(ctx);
            
            CGContextSetStrokeColorWithColor(ctx, [_axisColor CGColor]);
            CGContextSetLineWidth(ctx, _axisLineWidth);
            CGContextMoveToPoint(ctx, point.x - 0.5f, _axisHeight + _margin.top);
            CGContextAddLineToPoint(ctx, point.x - 0.5f, _axisHeight + _margin.top + 3);
            CGContextStrokePath(ctx);
        }
        
        for(int i=0;i<_verticalGridStep + 1;i++) {
            // If the value is zero then we display the horizontal axis
            CGFloat v = maxBound - (maxBound - minBound) / _verticalGridStep * i;
            
            if(v == 0) {
                CGContextSetLineWidth(ctx, _axisLineWidth);
                CGContextSetStrokeColorWithColor(ctx, [_axisColor CGColor]);
            } else {
                CGContextSetStrokeColorWithColor(ctx, [_innerGridColor CGColor]);
                CGContextSetLineWidth(ctx, _innerGridLineWidth);
            }
            
            CGPoint point = CGPointMake(_margin.left, (i) * _axisHeight / _verticalGridStep + _margin.top);
            
            CGContextMoveToPoint(ctx, point.x, point.y);
            CGContextAddLineToPoint(ctx, _axisWidth + _margin.left, point.y);
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
    CGFloat minBound = [self minVerticalBound];
    CGFloat maxBound = [self maxVerticalBound];
    CGFloat spread = maxBound - minBound;
    CGFloat scale = 0;
    
    if (spread != 0) {
        scale = _axisHeight / spread;
    }
    
    for (FSLinePlot *plot in self.plots) {
        
        BOOL smoothing = plot.bezierSmoothing;
        
        UIBezierPath *noPath = [self plot:plot getLinePath:0 withSmoothing:smoothing close:NO];
        UIBezierPath *path = [self plot:plot getLinePath:scale withSmoothing:smoothing close:NO];
        
        UIBezierPath *noFill = [self plot:plot getLinePath:0 withSmoothing:smoothing close:YES];
        UIBezierPath *fill = [self plot:plot getLinePath:scale withSmoothing:smoothing close:YES];
        
        if(plot.fillColor) {
            CAShapeLayer* fillLayer = [CAShapeLayer layer];
            fillLayer.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + minBound * scale, self.bounds.size.width, self.bounds.size.height);
            fillLayer.bounds = self.bounds;
            fillLayer.path = fill.CGPath;
            fillLayer.strokeColor = nil;
            fillLayer.fillColor = plot.fillColor.CGColor;
            fillLayer.lineWidth = 0;
            fillLayer.lineJoin = kCALineJoinRound;
            
            [_graphLayer addSublayer:fillLayer];
            [self.layers addObject:fillLayer];
            
            CABasicAnimation *fillAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
            fillAnimation.duration = _animationDuration;
            fillAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            fillAnimation.fillMode = kCAFillModeForwards;
            fillAnimation.fromValue = (id)noFill.CGPath;
            fillAnimation.toValue = (id)fill.CGPath;
            [fillLayer addAnimation:fillAnimation forKey:@"path"];
        }
        
        CAShapeLayer *pathLayer = [CAShapeLayer layer];
        pathLayer.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + minBound * scale, self.bounds.size.width, self.bounds.size.height);
        pathLayer.bounds = self.bounds;
        pathLayer.path = path.CGPath;
        pathLayer.strokeColor = [plot.color CGColor];
        pathLayer.fillColor = nil;
        pathLayer.lineWidth = plot.lineWidth;
        pathLayer.lineJoin = kCALineJoinRound;
        
        [_graphLayer addSublayer:pathLayer];
        [self.layers addObject:pathLayer];
        
        if(plot.fillColor) {
            CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
            pathAnimation.duration = _animationDuration;
            pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            pathAnimation.fromValue = (__bridge id)(noPath.CGPath);
            pathAnimation.toValue = (__bridge id)(path.CGPath);
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
    CGFloat minBound = [self minVerticalBound];
    CGFloat maxBound = [self maxVerticalBound];
    CGFloat spread = maxBound - minBound;
    CGFloat scale = 0;
    
    if (spread != 0) {
        scale = _axisHeight / spread;
    }
    
    FSPointData *data = plot.data;
    CGPoint *points = data.points;
    
    for(int i= 0;i<data.count;i++) {
        CGPoint p = [self translateAndScalePoint:points[i]];
        p.y +=  minBound * scale;
        
        UIBezierPath* circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(p.x - plot.dataPointRadius, p.y - plot.dataPointRadius, plot.dataPointRadius * 2, plot.dataPointRadius * 2)];
        
        CAShapeLayer *fillLayer = [CAShapeLayer layer];
        fillLayer.frame = CGRectMake(p.x, p.y, plot.dataPointRadius, plot.dataPointRadius);
        fillLayer.bounds = CGRectMake(p.x, p.y, plot.dataPointRadius, plot.dataPointRadius);
        fillLayer.path = circle.CGPath;
        fillLayer.strokeColor = plot.dataPointColor.CGColor;
        fillLayer.fillColor = plot.dataPointBackgroundColor.CGColor;
        fillLayer.lineWidth = 1;
        fillLayer.lineJoin = kCALineJoinRound;
        
        [_graphLayer addSublayer:fillLayer];
        [self.layers addObject:fillLayer];
    }
}

#pragma mark - Chart scale & boundaries

- (CGFloat)horizontalScale
{
    CGFloat scale = 1.0f;
    _maxCount = 0;
    
    for (FSLinePlot *plot in self.plots) {
        _maxCount = MAX(_maxCount, plot.data.count);
    }
    NSInteger q = (int)_maxCount / _horizontalGridStep;
    
    if(_maxCount > 1) {
        scale = (CGFloat)(q * _horizontalGridStep) / (CGFloat)(_maxCount - 1);
    }
    
    return scale;
}

- (CGFloat)minVerticalBound
{
    return MIN(CGRectGetMinY(_visibleRegion), 0);
}

- (CGFloat)maxVerticalBound
{
    return MAX(CGRectGetMaxY(_visibleRegion), 0);
}

#pragma mark - Chart utils

- (CGFloat)getUpperRoundNumber:(CGFloat)value forGridStep:(int)gridStep
{
    if(value <= 0)
        return 0;
    
    // We consider a round number the following by 0.5 step instead of true round number (with step of 1)
    CGFloat logValue = log10f(value);
    CGFloat scale = powf(10, floorf(logValue));
    CGFloat n = ceilf(value / scale * 4);
    
    int tmp = (int)(n) % gridStep;
    
    if(tmp != 0) {
        n += gridStep - tmp;
    }
    
    return n * scale / 4.0f;
}

- (void)setGridStep:(int)gridStep
{
    _verticalGridStep = gridStep;
    _horizontalGridStep = gridStep;
}

- (CGPoint)translateAndScalePoint:(CGPoint)point{
    
    CGFloat x =  point.x * _xScale - _visibleRegion.origin.x;
    CGFloat y = (_axisHeight - point.y * _yScale) - _visibleRegion.origin.y;
    
    return CGPointMake(x, y);
    
}

- (UIBezierPath*)plot:(FSLinePlot *)plot
          getLinePath:(float)scale
        withSmoothing:(BOOL)smoothed
                close:(BOOL)closed
{
    UIBezierPath* path = [UIBezierPath bezierPath];
    
    FSPointData *data = plot.data;
    CGPoint *points = data.points;
    
    if(smoothed) {
        for(int i=0;i<data.count - 1;i++) {
            CGPoint controlPoint[2];
            CGPoint p = [self translateAndScalePoint:points[i]];
            if (scale == 0)p.y = _axisHeight;
            
            // Start the path drawing
            if(i == 0)
                [path moveToPoint:p];
            
            CGPoint nextPoint, previousPoint, m;
            
            // First control point
            nextPoint = [self translateAndScalePoint:points[i + 1]];
            if (scale == 0)nextPoint.y = _axisHeight;
            previousPoint = [self translateAndScalePoint:points[i - 1]];
            if (scale == 0)previousPoint.y = _axisHeight;
            
            m = CGPointZero;
            
            if(i > 0) {
                m.x = (nextPoint.x - previousPoint.x) / 2;
                m.y = (nextPoint.y - previousPoint.y) / 2;
            } else {
                m.x = (nextPoint.x - p.x) / 2;
                m.y = (nextPoint.y - p.y) / 2;
            }
            
            controlPoint[0].x = p.x + m.x * plot.bezierSmoothingTension;
            controlPoint[0].y = p.y + m.y * plot.bezierSmoothingTension;
            
            // Second control point
            nextPoint = [self translateAndScalePoint:points[i + 2]];
            if (scale == 0)nextPoint.y = _axisHeight;
            
            previousPoint = [self translateAndScalePoint:points[i]];
            if (scale == 0)previousPoint.y = _axisHeight;
            
            p = [self translateAndScalePoint:points[i + 1]];
            if (scale == 0)p.y = _axisHeight;
            
            m = CGPointZero;
            
            if(i < plot.data.count - 2) {
                m.x = (nextPoint.x - previousPoint.x) / 2;
                m.y = (nextPoint.y - previousPoint.y) / 2;
            } else {
                m.x = (p.x - previousPoint.x) / 2;
                m.y = (p.y - previousPoint.y) / 2;
            }
            
            controlPoint[1].x = p.x - m.x * plot.bezierSmoothingTension;
            controlPoint[1].y = p.y - m.y * plot.bezierSmoothingTension;
            
            [path addCurveToPoint:p controlPoint1:controlPoint[0] controlPoint2:controlPoint[1]];
        }
        
    } else {
        for(int i=0;i<data.count;i++) {
            if(i > 0) {
                
                CGPoint p = [self translateAndScalePoint:points[i]];
                if (scale == 0)p.y = _axisHeight;
                [path addLineToPoint:p];
            } else {
                
                CGPoint p = [self translateAndScalePoint:points[i]];
                if (scale == 0)p.y = _axisHeight;
                [path moveToPoint:p];
            }
        }
    }
    
    if(closed) {
        
        CGPoint p = [self translateAndScalePoint:points[data.count - 1]];
        if (scale == 0)p.y = _axisHeight;
        
        // Closing the path for the fill drawing
        [path addLineToPoint:p];
        
        p = [self translateAndScalePoint:points[data.count - 1]];
        p.y = _axisHeight;
        [path addLineToPoint:p];
        p = [self translateAndScalePoint:points[0]];
        p.y = _axisHeight;
        [path addLineToPoint:p];
        
        p = [self translateAndScalePoint:points[0]];
        if (scale == 0)p.y = _axisHeight;
        [path addLineToPoint:p];
    }
    
    return path;
}


@end
