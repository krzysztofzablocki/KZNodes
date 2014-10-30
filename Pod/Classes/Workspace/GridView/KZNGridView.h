//
//  Created by merowing on 29/10/14.
//
//
//


@import Foundation;
@import UIKit;
@class KZNSocket;
@class KZNNode;
@class KZNWorkspace;

@interface KZNGridView : UIView
@property(nonatomic, assign) CGPoint offset;
@property(nonatomic, weak) KZNWorkspace *workspace;

- (void)updateConnections;

- (void)prepareConnectionLayerForSocket:(KZNSocket *)socket;

- (void)addNode:(KZNNode *)node;

- (void)removeNode:(KZNNode *)node;

- (void)clearConnectionLayerForSocket:(KZNSocket *)inputSocket;
@end