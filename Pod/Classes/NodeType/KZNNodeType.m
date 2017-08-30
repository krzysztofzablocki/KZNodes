//
//  Created by merowing on 29/10/14.
//
//
//

@import ObjectiveC.runtime;

#import <objc/runtime.h>
#import "KZNNodeType.h"
#import "KZNNode.h"

static void const *kNodeTypesKey = &kNodeTypesKey;

@interface KZNNodeType ()
@property(nonatomic, strong, readonly) NSMutableArray *inputSocketsBuilders;
@property(nonatomic, strong, readonly) NSMutableArray *outputSocketsBuilders;
@property(nonatomic, assign, readwrite) NSString *name;
@end

@implementation KZNNodeType

+ (KZNNodeType *)registerType:(NSString *)typeName inputs:(NSDictionary *)inputs outputs:(NSDictionary *)outputs processingBlock:(void (^)(id, NSDictionary *, NSMutableDictionary *))processingBlock
{
  return [self registerType:typeName withClass:KZNNode.class inputs:inputs outputs:outputs processingBlock:processingBlock];
}

+ (KZNNodeType *)registerType:(NSString *)typeName withClass:(Class)nodeClass inputs:(NSDictionary *)inputs outputs:(NSDictionary *)outputs processingBlock:(void (^)(id node, NSDictionary *inputs, NSMutableDictionary *outputs))processingBlock
{
  return [self registerType:typeName withBuilder:^(KZNNodeType *type) {
    type.baseNodeClass = nodeClass;
    [inputs enumerateKeysAndObjectsUsingBlock:(void (^)(id, id, BOOL *))^(NSString *name, Class dataType, BOOL *stop) {
      [type addSocket:KZNNodeSocketTypeInput name:name type:dataType];
    }];

    [outputs enumerateKeysAndObjectsUsingBlock:(void (^)(id, id, BOOL *))^(NSString *name, Class dataType, BOOL *stop) {
      [type addSocket:KZNNodeSocketTypeOutput name:name type:dataType];
    }];

    type.processingBlock = processingBlock;
  }];
}

+ (KZNNodeType *)registerType:(NSString *)typeName withBuilder:(void (^)(KZNNodeType *))builderBlock
{
  id __unused existingType = self.nodeTypes[typeName];
//  NSAssert(existingType, @"Can't register node for type %@, already exist", typeName);

  KZNNodeType *type = [KZNNodeType new];
  type.name = typeName;
  builderBlock(type);
  BOOL isValid = [type validate];
  if (!isValid) {
    NSLog(@"Ignoring node type %@, because it's invalid", typeName);
    return nil;
  }
  self.nodeTypes[typeName] = type;
  return type;
}

- (instancetype)init
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _inputSocketsBuilders = [NSMutableArray new];
  _outputSocketsBuilders = [NSMutableArray new];
  _baseNodeClass = KZNNode.class;
  return self;
}


- (void)addSocket:(KZNNodeSocketType)type name:(NSString *)name type:(Class)dataType
{
  KZNSocket *(^socketCreationBlock)() = ^() {
    return [KZNSocket socketWithName:name socketType:type dataType:dataType];
  };

  if (type == KZNNodeSocketTypeInput) {
    [self.inputSocketsBuilders addObject:socketCreationBlock];
  } else {
    [self.outputSocketsBuilders addObject:socketCreationBlock];
  }
}

- (BOOL)validate
{
  if (!self.processingBlock) {
    NSLog(@"Missing processing block");
    return NO;
  }

  if (!self.inputSocketsBuilders.count && !self.outputSocketsBuilders.count) {
    NSLog(@"Either input or output sockets are required");
    return NO;
  }

  if (!self.baseNodeClass) {
    NSLog(@"invalid node class %@", NSStringFromClass(self.baseNodeClass));
    return NO;
  }

  return YES;
}

#pragma mark - Helpers

+ (NSMutableDictionary *)nodeTypes
{
  NSMutableDictionary *nodeTypes = objc_getAssociatedObject(self, kNodeTypesKey);
  if (!nodeTypes) {
    nodeTypes = [NSMutableDictionary new];
  }
  objc_setAssociatedObject(self, kNodeTypesKey, nodeTypes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  return nodeTypes;
}

- (KZNNode *)createNode
{
  NSMutableArray *inSockets = [NSMutableArray new];
  NSMutableArray *outSockets = [NSMutableArray new];
  for (KZNSocket *(^builder)()
    in self.inputSocketsBuilders) {
    [inSockets addObject:builder()];
  }

  for (KZNSocket *(^builder)()
    in self.outputSocketsBuilders) {
    [outSockets addObject:builder()];
  }

  KZNNode *node = [self.baseNodeClass nodeWithType:self inputSockets:inSockets outputSockets:outSockets];
  if (self.nodeSetup) {
    self.nodeSetup(node);
  }
  return node;
}

@end
