//
//  Created by merowing on 29/10/14.
//
//
//


@import Foundation;
@import UIKit;

#import "KZNNode.h"


@interface KZNNodeWithSlider : KZNNode
@property(nonatomic, weak) IBOutlet UISlider *slider;
- (void)forceLabelUpdate;
@end
