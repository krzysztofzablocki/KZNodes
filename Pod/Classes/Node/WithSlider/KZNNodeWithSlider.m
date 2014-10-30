//
//  Created by merowing on 29/10/14.
//
//
//


#import "KZNNodeWithSlider.h"
#import "KZNWorkspace.h"
#import "KZNNodeType.h"


@interface KZNNodeWithSlider ()
@property(weak, nonatomic) IBOutlet UILabel *valueLabel;
@end

@implementation KZNNodeWithSlider : KZNNode
- (void)setupWithType:(KZNNodeType *)type inputSockets:(NSArray *)inputSockets outputSockets:(NSArray *)outputSockets
{
  [super setupWithType:type inputSockets:inputSockets outputSockets:outputSockets];
  [self.slider setThumbImage:[UIImage imageNamed:@"sliderHandler"] forState:UIControlStateNormal];
  [self.slider setThumbImage:[UIImage imageNamed:@"sliderHandler"] forState:UIControlStateHighlighted];
  [self.slider addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
  [self valueChanged:self.slider];
}

- (void)valueChanged:(UISlider *)slider
{
  self.valueLabel.text = [NSString stringWithFormat:@"%.2f", slider.value];
  [self.valueLabel sizeToFit];
  [self.workspace evaluate];
}

@end