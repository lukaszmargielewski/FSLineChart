//
//  FSLineChart.h
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

#import <UIKit/UIKit.h>
#import "FSLinePlot.h"


@interface FSLineChart : UIView

// Block definition for getting a label for a set index (use case: date, units,...)
typedef NSString *(^FSLabelForIndexGetter)(NSUInteger index);

// Same as above, but for the value (for adding a currency, or a unit symbol for example)
typedef NSString *(^FSLabelForValueGetter)(CGFloat value);
// Same as above, but for the value (for adding a currency, or a unit symbol for example)
typedef UIImage *(^FSIconForValueGetter)(CGFloat value);

typedef NS_ENUM(NSInteger, ValueLabelPositionType) {
    ValueLabelLeft,
    ValueLabelRight,
    ValueLabelLeftMirrored
};

// Index label properties
@property (copy) FSLabelForIndexGetter labelForIndex;
@property (nonatomic, strong) UIFont* indexLabelFont;
@property (nonatomic) UIColor* indexLabelTextColor;
@property (nonatomic) UIColor* indexLabelBackgroundColor;

// Value label properties
@property (copy) FSLabelForValueGetter  labelForValue;
@property (copy) FSIconForValueGetter   iconForValue;

@property (nonatomic, strong) UIFont* valueLabelFont;
@property (nonatomic) UIColor* valueLabelTextColor;
@property (nonatomic) UIColor* valueLabelBackgroundColor;
@property (nonatomic) UIColor* valueIconBackgroundColor;
@property (nonatomic) ValueLabelPositionType valueLabelPosition;

// Number of visible step in the chart
@property (nonatomic) int gridStep;
@property (nonatomic) int verticalGridStep;
@property (nonatomic) int horizontalGridStep;

// Margin of the chart
@property (nonatomic) UIEdgeInsets margin;
@property (nonatomic) CGRect visibleRegion;

// Decoration parameters, let you pick the color of the line as well as the color of the axis
@property (nonatomic, strong) UIColor* axisColor;
@property (nonatomic) CGFloat axisLineWidth;

// Grid parameters
@property (nonatomic) BOOL drawInnerGrid;
@property (nonatomic, strong) UIColor* innerGridColor;
@property (nonatomic) CGFloat innerGridLineWidth;

// Animations
@property (nonatomic) CGFloat animationDuration;

// Set the actual data for the chart, and then render it to the view.
- (void)addPlot:(FSLinePlot *)plot;

// Clear all rendered data from the view.
- (void)clearAllPlots;

- (void)repositionPlots;

// Get the bounds of the chart
- (CGFloat)minVerticalBound;
- (CGFloat)maxVerticalBound;


@end
