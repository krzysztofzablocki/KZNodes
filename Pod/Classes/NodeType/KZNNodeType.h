//
//  Created by merowing on 29/10/14.
//
//
//


@import Foundation;
@import UIKit;

#import "KZNSocket.h"

typedef NS_ENUM(NSUInteger, KZNEvaluationMode) {
  KZNEvaluationModeOnChange = 0,
  KZNEvaluationModeContinuous
};

@interface KZNNodeType : NSObject
@property(nonatomic, assign, readonly) NSString *name;
@property(nonatomic, copy) void (^processingBlock)(id node, NSDictionary *inputs, NSMutableDictionary *outputs);
@property(nonatomic, weak) Class baseNodeClass;
@property(nonatomic, assign) KZNEvaluationMode evaluationMode;
@property(nonatomic, copy) void (^nodeSetup)(id);

+ (NSMutableDictionary *)nodeTypes;

+ (KZNNodeType *)registerType:(NSString *)typeName inputs:(NSDictionary *)inputs outputs:(NSDictionary *)outputs processingBlock:(void (^)(id node, NSDictionary *inputs, NSMutableDictionary *outputs))processingBlock __attribute__((nonnull(1, 4)));
+ (KZNNodeType *)registerType:(NSString *)typeName withClass:(Class)nodeClass inputs:(NSDictionary *)inputs outputs:(NSDictionary *)outputs processingBlock:(void (^)(id node, NSDictionary *inputs, NSMutableDictionary *outputs))processingBlock __attribute__((nonnull(1, 2, 5)));
+ (KZNNodeType *)registerType:(NSString *)typeName withBuilder:(void (^)(KZNNodeType *))builderBlock __attribute__((nonnull));

- (void)addSocket:(KZNNodeSocketType)type name:(NSString *)name type:(Class)class;

- (KZNNode *)createNode;
@end