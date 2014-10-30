//
//  Created by merowing on 29/10/14.
//
//
//


#import "KZNNodeWithText.h"
#import "KZNWorkspace.h"
#import "KZNNodeType.h"


@interface KZNNodeWithText ()
@end

@implementation KZNNodeWithText : KZNNode
- (void)setupWithType:(KZNNodeType *)type inputSockets:(NSArray *)inputSockets outputSockets:(NSArray *)outputSockets
{
  [super setupWithType:type inputSockets:inputSockets outputSockets:outputSockets];
  [self.textField addTarget:self action:@selector(textChanged) forControlEvents:UIControlEventEditingChanged];

  self.textField.layer.borderColor = [UIColor colorWithRed:0.462 green:0.517 blue:0.552 alpha:1].CGColor;
  self.textField.layer.borderWidth = 1.0f;
  self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"XXX VALUE" attributes:@{
    NSFontAttributeName : [UIFont fontWithName:@"AvenirNext-Regular" size:12],
    NSForegroundColorAttributeName : [UIColor colorWithRed:0.462 green:0.517 blue:0.552 alpha:1]
  }];
  self.textField.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0);
}

- (void)textChanged
{
  [self.workspace evaluate];
}

@end