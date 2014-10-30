//
//  Created by merowing on 29/10/14.
//
//
//


@import Foundation;
@import UIKit;

@class KZNNode;


typedef NS_ENUM(NSUInteger, KZNNodeSocketType) {
  KZNNodeSocketTypeInput = 0,
  KZNNodeSocketTypeOutput = 1
};


@interface KZNSocket : UIView
@property(nonatomic, weak) IBOutlet UIView *containerView;
@property(nonatomic, copy, readonly) NSString *name;
@property(nonatomic, weak, readonly) Class type;
@property(nonatomic, assign, readonly) KZNNodeSocketType socketType;
@property(nonatomic, strong, readonly) UIColor *color;
@property(nonatomic, weak, readonly) CAShapeLayer *shapeLayer;
@property(nonatomic, weak, readonly) KZNNode *parent;
@property(nonatomic, strong, readonly) NSSet *connections;
@property(nonatomic, strong) KZNSocket *sourceSocket;

+ (instancetype)socketWithName:(NSString *)name socketType:(KZNNodeSocketType)socketType dataType:(Class)type;

- (void)setupWithName:(NSString *)name socketType:(KZNNodeSocketType)socketType dataType:(Class)type;

- (void)addConnectionToSocket:(KZNSocket *)inputSocket;

- (void)removeConnectionToSocket:(KZNSocket *)inputSocket;

- (CGPoint)socketCenter;

- (BOOL)canConnectToSocket:(KZNSocket *)other;

- (void)setCompatible:(BOOL)isCompatible;
@end