//
//  Created by merowing on 29/10/14.
//
//
//


@import Foundation;
@import UIKit;
@class KZNNode;
@class KZNSocket;

@interface KZNWorkspace : UIView
@property(nonatomic, weak, readonly) IBOutlet UIView *previewView;

+ (instancetype)workspaceWithBounds:(CGRect)bounds;

- (void)addNode:(KZNNode *)node;

- (void)removeNode:(KZNNode *)node;

- (void)pressedSocket:(KZNSocket *)socket;

- (void)breakConnectionFromSocket:(KZNSocket *)outputSocket toSocket:(KZNSocket *)inputSocket;

- (void)evaluate;
@end