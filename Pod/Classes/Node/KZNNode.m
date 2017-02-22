//
//  Created by merowing on 29/10/14.
//
//
//


#import "KZNNode.h"
#import "KZNSocket+Internal.h"
#import "KZNNodeType.h"
#import "KZNWorkspace.h"


@interface KZNNode ()
@property(nonatomic, weak) IBOutlet UILabel *label;

@property(nonatomic, assign) NSUInteger evaluationTick;
@property(nonatomic, copy) NSDictionary *evaluationResults;
@property(nonatomic, assign) NSUInteger const verticalSpacing;
@property(nonatomic) NSInteger socketHorizontalSpacing;
@end

@implementation KZNNode
+ (UINib *)matchingNib
{
  if ([[NSBundle mainBundle] pathForResource:NSStringFromClass(self.class) ofType:@"nib"]) {
    return [UINib nibWithNibName:NSStringFromClass(self.class) bundle:[NSBundle mainBundle]];
  }

  if ([[NSBundle bundleForClass:[KZNNode class]] pathForResource:NSStringFromClass(self.class) ofType:@"nib"]) {
    return [UINib nibWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
  }

  return [UINib nibWithNibName:NSStringFromClass(KZNNode.class) bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)nodeWithType:(KZNNodeType *)type inputSockets:(NSArray *)inputSockets outputSockets:(NSArray *)outputSockets
{
  UINib *nib = [self matchingNib];
  KZNNode *node = [self new];
  UIView *containerView = [[nib instantiateWithOwner:node options:nil] firstObject];
  node.bounds = containerView.bounds;
  [node addSubview:containerView];
  if (!node) {
    return nil;
  }

  [node setupWithType:type inputSockets:inputSockets outputSockets:outputSockets];
  return node;
}

- (void)setupWithType:(KZNNodeType *)type inputSockets:(NSArray *)inputSockets outputSockets:(NSArray *)outputSockets
{
  _type = type;
  self.label.text = [NSString stringWithFormat:@" %@", [type.name uppercaseString]];

  [self sizeToFit];
  _inputSockets = [inputSockets copy];
  _outputSockets = [outputSockets copy];

  self.layer.shadowOpacity = 0.75;
  self.layer.shadowColor = UIColor.blackColor.CGColor;
  self.layer.shadowOffset = CGSizeMake(0, 1);

  self.verticalSpacing = 5;
  self.socketHorizontalSpacing = 5;

  for (KZNSocket *socket in inputSockets) {
    [socket sizeToFit];
    socket.parent = self;
    [self addSubview:socket];
  }

  for (KZNSocket *socket in outputSockets) {
    [socket sizeToFit];
    socket.parent = self;
    [self addSubview:socket];
  }

  [self sizeToFit];
}

- (CGSize)sizeThatFits:(CGSize)size
{
  __block CGFloat inputHeight = 0;
  [self.inputSockets enumerateObjectsUsingBlock:^(KZNSocket *socket, NSUInteger idx, BOOL *stop) {
    inputHeight += CGRectGetHeight(socket.bounds) + self.verticalSpacing;
  }];
  __block CGFloat outputHeight = 0;
  [self.outputSockets enumerateObjectsUsingBlock:^(KZNSocket *socket, NSUInteger idx, BOOL *stop) {
    outputHeight += CGRectGetHeight(socket.bounds) + self.verticalSpacing;
  }];

  __block CGFloat maxY = 0;
  [self.containerView.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
    if ([subview isKindOfClass:KZNSocket.class]) {
      return;
    }
    maxY = MAX(maxY, CGRectGetMaxY(subview.frame));
  }];

  return CGSizeMake(256, MAX(maxY, (MAX(inputHeight, outputHeight) + self.socketStartYPosition)) + self.verticalSpacing);
}

- (NSUInteger)socketStartYPosition
{
  const NSUInteger initialOffset = 8;
  return (NSUInteger)(roundf(CGRectGetMaxY(self.label.frame) + initialOffset));
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  __block CGFloat yPosition = self.socketStartYPosition;
  [self.inputSockets enumerateObjectsUsingBlock:^(KZNSocket *socket, NSUInteger idx, BOOL *stop) {
    socket.center = CGPointMake(CGRectGetWidth(socket.bounds) * 0.5f + self.socketHorizontalSpacing, yPosition + CGRectGetHeight(socket.bounds) * 0.5f);
    yPosition = CGRectGetMaxY(socket.frame) + self.verticalSpacing;
    socket.frame = CGRectIntegral(socket.frame);
  }];

  yPosition = self.socketStartYPosition;
  [self.outputSockets enumerateObjectsUsingBlock:^(KZNSocket *socket, NSUInteger idx, BOOL *stop) {
    socket.center = CGPointMake(CGRectGetWidth(self.bounds) - CGRectGetWidth(socket.bounds) * 0.5f - self.socketHorizontalSpacing, yPosition + CGRectGetHeight(socket.bounds) * 0.5f);
    yPosition = CGRectGetMaxY(socket.frame) + self.verticalSpacing;
    socket.frame = CGRectIntegral(socket.frame);
  }];
}

- (KZNSocket *)socketForTouchPoint:(CGPoint)point
{
  CGFloat margin = 10;

  for (KZNSocket *socket in self.inputSockets) {
    if (CGRectContainsPoint(CGRectInset(socket.frame, -margin, -margin), point)) {
      return socket;
    }
  }

  for (KZNSocket *socket in self.outputSockets) {
    if (CGRectContainsPoint(CGRectInset(socket.frame, -margin, -margin), point)) {
      return socket;
    }
  }

  return nil;
}

- (BOOL)canDragWithPoint:(CGPoint)point
{
  if ([self socketForTouchPoint:point]) {
    return NO;
  }

  return CGRectContainsPoint(self.bounds, point);
}

- (NSDictionary *)evaluateWithTick:(NSUInteger)tick withForwardPropagation:(BOOL)forwardPropagation
{
  if (tick != self.evaluationTick) {
    self.evaluationTick = tick;
    NSMutableDictionary *evaluation = [NSMutableDictionary new];
    [self.inputSockets enumerateObjectsUsingBlock:^(KZNSocket *socket, NSUInteger idx, BOOL *stop) {
      NSDictionary *result = [socket.sourceSocket.parent evaluateWithTick:tick withForwardPropagation:NO];
      id socketValue = result[socket.sourceSocket.name];
      if (socketValue) {
        evaluation[socket.name] = socketValue;
      }
    }];

    NSMutableDictionary *evaluationOutput = [NSMutableDictionary new];
    void (^processingBlock)(id, NSDictionary *, NSMutableDictionary *) = [(id)self.type performSelector:@selector(processingBlock)];
    processingBlock(self, evaluation, evaluationOutput);
    self.evaluationResults = evaluationOutput;

    if (forwardPropagation) {
      [self.outputSockets enumerateObjectsUsingBlock:^(KZNSocket *socket, NSUInteger idx, BOOL *stop) {
        [socket.connections enumerateObjectsUsingBlock:^(KZNSocket *connectedSocket, BOOL *stop) {
          [connectedSocket.parent evaluateWithTick:tick withForwardPropagation:forwardPropagation];
        }];
      }];
    }
  }

  return self.evaluationResults;
}

- (IBAction)destroyButtonPressed:(id)sender
{
  [self.workspace removeNode:self];
}
@end
