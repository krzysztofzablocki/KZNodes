//
//  Created by merowing on 29/10/14.
//
//
//

@import ObjectiveC.runtime;

#import <objc/runtime.h>
#import "KZNWorkspace.h"
#import "KZNNode.h"
#import "KZNSocket.h"
#import "KZNSocket+Internal.h"
#import "KZNNodeType.h"
#import "KZNGridView.h"
#import "KZNNodeWithText.h"
#import "KZNNodeWithSlider.h"

// NodeTypes
static NSString * const kNodeTypeStandard = @"KZNNode";
static NSString * const kNodeTypeWithSlider = @"KZNNodeWithSlider";
static NSString * const kNodeTypeWithText = @"KZNNodeWithText";

// Storage Array definitions
static NSString * const kNodeIndex = @"NodeIndex";
static NSString * const kNodeName = @"NodeName";
static NSString * const kNodePositionX = @"PositionX";
static NSString * const kNodePositionY = @"PositionY";
static NSString * const kNodeEvaluationMode = @"EvaluationMode";
static NSString * const kNodeClassName = @"ClassName";
static NSString * const kNodeSliderValue = @"SliderValue";
static NSString * const kNodeTextValue = @"TextValue";
static NSString * const kSocketsDefinition = @"inputSocketsDefinition";
static NSString * const kSocketName = @"SocketName";
static NSString * const kNodeDestionationIndex = @"ToNode";
static NSString * const kSocketDestinationName = @"ToSocketName";


@interface KZNWorkspace () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) NSMutableArray *nodes;

@property(nonatomic, assign) NSUInteger evaluationTick;
@property(nonatomic, weak) CADisplayLink *displayLink;
@property(nonatomic, weak, readwrite) UIView *previewView;
@property(nonatomic, weak) IBOutlet UITableView *tableView;
@property(nonatomic, weak) IBOutlet KZNGridView *gridView;
@property(nonatomic, copy) NSArray *nodeTypes;
@end

@implementation KZNWorkspace

+ (instancetype)workspaceWithBounds:(CGRect)bounds
{
  KZNWorkspace *workspace = [[[UINib nibWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self]] instantiateWithOwner:nil options:nil] firstObject];
  workspace.bounds = bounds;
  return workspace;
}


- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self) {
    [self setup];
  }

  return self;
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.gridView.workspace = self;
}

- (void)addNode:(KZNNode *)node
{
  node.workspace = self;
  [self.nodes addObject:node];
  [self.gridView addNode:node];
}

- (void)removeNode:(KZNNode *)node
{
  [node.inputSockets enumerateObjectsUsingBlock:^(KZNSocket *socket, NSUInteger idx, BOOL *stop) {
    [self breakConnectionFromSocket:socket.sourceSocket toSocket:socket];
  }];
  [node.outputSockets enumerateObjectsUsingBlock:^(KZNSocket *socket, NSUInteger idx, BOOL *stop) {
    [socket.connections enumerateObjectsUsingBlock:^(KZNSocket *inputSocket, BOOL *stop) {
      [self breakConnectionFromSocket:inputSocket.sourceSocket toSocket:inputSocket];
    }];
  }];

  node.workspace = nil;
  [self.nodes removeObject:node];
  [self.gridView removeNode:node];
}


- (void)setup
{
  self.nodes = [NSMutableArray new];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
  [super willMoveToWindow:newWindow];

  if (newWindow) {
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(refresh:)];
    self.displayLink = displayLink;
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
  } else {
    [self.displayLink invalidate];
    self.displayLink = nil;
  }
}


- (void)refresh:(CADisplayLink *)refresh
{
  self.evaluationTick++;
  [self.nodes enumerateObjectsUsingBlock:^(KZNNode *node, NSUInteger idx, BOOL *stop) {
    if (node.type.evaluationMode == KZNEvaluationModeContinuous) {
      [node evaluateWithTick:self.evaluationTick withForwardPropagation:YES];
    }
  }];
}

- (void)pressedSocket:(KZNSocket *)socket
{
  if ([socket isKindOfClass:KZNSocket.class] && socket.socketType == KZNNodeSocketTypeInput && socket.sourceSocket) {
    [self breakConnectionFromSocket:socket.sourceSocket toSocket:socket];
  }
}

- (void)breakConnectionFromSocket:(KZNSocket *)outputSocket toSocket:(KZNSocket *)inputSocket
{
  [self.gridView clearConnectionLayerForSocket:inputSocket];
  [outputSocket removeConnectionToSocket:inputSocket];
  [self evaluate];
}

- (void)evaluate
{
  NSMutableArray *finalNodes = [NSMutableArray new];
  [self.nodes enumerateObjectsUsingBlock:^(KZNNode *node, NSUInteger idx, BOOL *stop) {
    if (!node.outputSockets.count) {
      [finalNodes addObject:node];
      return;
    }

    __block BOOL finalNode = YES;
    [node.outputSockets enumerateObjectsUsingBlock:^(KZNSocket *socket, NSUInteger idx, BOOL *stop) {
      if ([socket.connections count]) {
        finalNode = NO;
        *stop = YES;
      }
    }];

    if (finalNode) {
      [finalNodes addObject:node];
    }
  }];

  [self evaluateNodes:finalNodes];
}

- (void)evaluateNodes:(NSArray *)nodes
{
  self.evaluationTick++;
  [nodes enumerateObjectsUsingBlock:^(KZNNode *node, NSUInteger idx, BOOL *stop) {
    [self evaluateNode:node withEvaluationTick:self.evaluationTick];
  }];
}


- (NSDictionary *)evaluateNode:(KZNNode *)node withEvaluationTick:(NSUInteger)tick
{
  if (!node) {
    return @{ };
  }

  return [node evaluateWithTick:tick withForwardPropagation:NO];
}

#pragma mark - UITableView DS

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  [tableView registerNib:[UINib nibWithNibName:@"KZNWorkspaceBlockCell" bundle:[NSBundle bundleForClass:self.class]] forCellReuseIdentifier:@"DefaultCell"];
  tableView.separatorColor = [UIColor colorWithRed:0.129 green:0.137 blue:0.141 alpha:1];

  self.nodeTypes = [KZNNodeType nodeTypes].allValues;
  return self.nodeTypes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DefaultCell" forIndexPath:indexPath];
  cell.backgroundColor = cell.textLabel.backgroundColor;
  KZNNodeType *nodeType = self.nodeTypes[indexPath.row];
  cell.textLabel.text = [[nodeType name] uppercaseString];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  KZNNode *node = [self.nodeTypes[indexPath.row] createNode];
  node.center = self.center;
  [self addNode:node];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Storage

- (NSArray*)arrayWithNodesComposition
{
  NSMutableArray *objectsToStore = [NSMutableArray array];

  for (int index = 0; index < self.nodes.count; index++) {
    KZNNode *node = self.nodes[index];
    NSString *nodeBaseClass = NSStringFromClass ([node class]);

    NSMutableDictionary *currentNode = [NSMutableDictionary dictionary];
    [currentNode setObject:[NSNumber numberWithInt:index] forKey:kNodeIndex];
    [currentNode setObject:node.type.name forKey:kNodeName];
    [currentNode setObject:[NSNumber numberWithInt: node.type.evaluationMode] forKey:kNodeEvaluationMode];
    [currentNode setObject:nodeBaseClass forKey:kNodeClassName];

    CGPoint center = node.center;
    [currentNode setObject:[NSNumber numberWithFloat:center.x] forKey:kNodePositionX];
    [currentNode setObject:[NSNumber numberWithFloat:center.y] forKey:kNodePositionY];

    NSMutableArray *inputSocketsDefinition = [NSMutableArray array];
    for (KZNSocket *socket in node.inputSockets) {
      for (KZNSocket *toSocket in socket.connections) {
        NSUInteger indexOfNode = [self.nodes indexOfObject:toSocket.parent];
        NSMutableDictionary *socketDefinition = [NSMutableDictionary dictionary];
        [socketDefinition setObject:socket.name forKey:kSocketName];
        [socketDefinition setObject:[NSNumber numberWithInteger:indexOfNode] forKey:kNodeDestionationIndex];
        [socketDefinition setObject:toSocket.name forKey:kSocketDestinationName];

        [inputSocketsDefinition addObject:socketDefinition];
      }
    }

    if (inputSocketsDefinition.count != 0) {
      [currentNode setObject:inputSocketsDefinition forKey:kSocketsDefinition];
    }

    if ([nodeBaseClass isEqualToString:kNodeTypeWithSlider]) {
      KZNNodeWithSlider *nodeS = self.nodes[index];
      [currentNode setObject:[NSNumber numberWithFloat:nodeS.slider.value] forKey:kNodeSliderValue];
    }else if ([nodeBaseClass isEqualToString:kNodeTypeWithText]){
      KZNNodeWithText *nodeT = self.nodes[index];
      [currentNode setObject:nodeT.textField.text forKey:kNodeTextValue];
    }
    [objectsToStore addObject:currentNode];
  }
  return objectsToStore;
}

- (void)restoreNodesCompositionFrom:(NSArray*)serializedObjects removeNodesFromGrid:(BOOL)removeNodes;
{
  NSUInteger firstnodeId;
  if (removeNodes) {
    [self removeAllNodes];
    firstnodeId = 0;
  } else {
    firstnodeId = self.nodes.count;
  }

  // Restore nodes
  [self createNodesFrom:serializedObjects];

  // Restore socket links after nodes are drawn
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self createSocketLinksFrom:serializedObjects firstNodeIndex:firstnodeId];
  });

  [_gridView updateConnections];
}

- (void)createNodesFrom:(NSArray*)nodesArray
{
  for (NSDictionary *currentNode in nodesArray) {
    KZNNode *node = [[[KZNNodeType nodeTypes]objectForKey:[currentNode objectForKey:kNodeName]] createNode];
    CGPoint center = CGPointMake([[currentNode objectForKey:kNodePositionX]floatValue], [[currentNode objectForKey:kNodePositionY]floatValue]);
    node.center = center;
    node.type.evaluationMode = [[currentNode objectForKey:kNodeEvaluationMode]intValue];

    NSString *nodeBaseClass = [currentNode objectForKey:kNodeClassName];
    if ([nodeBaseClass isEqualToString:kNodeTypeWithSlider]) {
      KZNNodeWithSlider *nodeS = (KZNNodeWithSlider*)node;
      nodeS.slider.value = [[currentNode objectForKey:kNodeSliderValue] floatValue];
      [nodeS forceLabelUpdate];
      node = nodeS;
      nodeS = nil;
    }else if ([nodeBaseClass isEqualToString:kNodeTypeWithText]) {
      KZNNodeWithText *nodeT = (KZNNodeWithText*)node;
      nodeT.textField.text = [currentNode objectForKey:kNodeTextValue];
      node = nodeT;
      nodeT = nil;
    }
    [self addNode:node];
  }
}

- (void)createSocketLinksFrom:(NSArray*)nodesArray firstNodeIndex:(NSUInteger)firstNodeIndex
{
  for (NSDictionary *currentNode in nodesArray) {
    NSArray *inputDefinitions = [currentNode objectForKey:kSocketsDefinition];
    for (NSDictionary *socketDefinition in inputDefinitions) {
      NSUInteger currentNodeIndex = [[currentNode objectForKey:kNodeIndex]integerValue] + firstNodeIndex;
      NSString *socketName = [socketDefinition objectForKey:kSocketName];
      NSUInteger targetNodeIndex = [[socketDefinition objectForKey:kNodeDestionationIndex]integerValue] + firstNodeIndex;
      NSString *targetSocketName = [socketDefinition objectForKey:kSocketDestinationName];

      KZNSocket *inputSocket = [self inputSocketWithName:socketName fromNode:self.nodes[currentNodeIndex]];
      KZNSocket *outputSocket = [self outputSocketWithName:targetSocketName fromNode:self.nodes[targetNodeIndex]];

      [_gridView prepareConnectionLayerForSocket:inputSocket];
      [outputSocket addConnectionToSocket:inputSocket];
      [self evaluate];
      [_gridView updateConnections];
    }
  }
}

- (KZNSocket*)inputSocketWithName:(NSString*)socketName fromNode:(KZNNode*)node
{
  return [self socketWithName:socketName fromSockets:node.inputSockets];
}

- (KZNSocket*)outputSocketWithName:(NSString*)socketName fromNode:(KZNNode*)node
{
  return [self socketWithName:socketName fromSockets:node.outputSockets];
}

- (KZNSocket*)socketWithName:(NSString*)socketName fromSockets:(NSArray *)nodesArray
{
  KZNSocket* socket;
  for (KZNSocket *currentSocket in nodesArray) {
    if ([currentSocket.name isEqualToString:socketName]){
      if (currentSocket.connections.count == 0) return currentSocket;
      // If there is not a free socket, at least return the last one.
      socket = currentSocket;
    }
  }
  return socket;
}

- (void)removeAllNodes
{
  while (self.nodes.count != 0) {
    [self removeNode:self.nodes.lastObject];
  }
}

@end
