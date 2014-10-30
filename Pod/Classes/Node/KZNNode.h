//
//  Created by merowing on 29/10/14.
//
//
//


@import Foundation;
@import UIKit;

@class KZNNodeType;

@class KZNWorkspace;
@class KZNSocket;

@interface KZNNode : UIView
@property(nonatomic, weak) IBOutlet UIView *containerView;
@property(nonatomic, weak, readonly) KZNNodeType *type;
@property(nonatomic, weak) KZNWorkspace *workspace;

@property(nonatomic, strong, readonly) NSArray *inputSockets;
@property(nonatomic, strong, readonly) NSArray *outputSockets;

+ (instancetype)nodeWithType:(KZNNodeType *)type inputSockets:(NSArray *)inputSockets outputSockets:(NSArray *)outputSockets;

- (void)setupWithType:(KZNNodeType *)type inputSockets:(NSArray *)inputSockets outputSockets:(NSArray *)outputSockets NS_REQUIRES_SUPER;

- (KZNSocket *)socketForTouchPoint:(CGPoint)point;

- (BOOL)canDragWithPoint:(CGPoint)point;

- (NSDictionary *)evaluateWithTick:(NSUInteger)tick withForwardPropagation:(BOOL)forwardPropagation;
@end