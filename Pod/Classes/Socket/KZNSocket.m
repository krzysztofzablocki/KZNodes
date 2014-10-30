//
//  Created by merowing on 29/10/14.
//
//
//


#import "KZNSocket.h"
#import "KZNSocket+Internal.h"
#import "KZNNode.h"
#import "KZNWorkspace.h"

@interface KZNSocket ()
@property(weak, nonatomic) IBOutlet UIButton *socketButton;
@property(weak, nonatomic) IBOutlet UILabel *label;
@end

@implementation KZNSocket
+ (UINib *)matchingNibForSocketType:(KZNNodeSocketType)type
{
  NSString *nibName = [NSString stringWithFormat:@"%@_%@", NSStringFromClass(self.class), type == KZNNodeSocketTypeInput ? @"Input" : @"Output"];

  if ([[NSBundle mainBundle] pathForResource:nibName ofType:@"nib"]) {
    return [UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]];
  }

  nibName = [NSString stringWithFormat:@"%@_%@", NSStringFromClass(KZNSocket.class), type == KZNNodeSocketTypeInput ? @"Input" : @"Output"];
  return [UINib nibWithNibName:nibName bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)socketWithName:(NSString *)name socketType:(KZNNodeSocketType)socketType dataType:(Class)type
{
  UINib *nib = [self matchingNibForSocketType:socketType];

  KZNSocket *socket = [self new];
  UIView *containerView = [[nib instantiateWithOwner:socket options:nil] firstObject];
  socket.bounds = containerView.bounds;
  [socket addSubview:containerView];
  if (!socket) {
    return nil;
  }

  [socket setupWithName:name socketType:socketType dataType:type];
  return socket;
}

- (void)setupWithName:(NSString *)name socketType:(KZNNodeSocketType)socketType dataType:(Class)type
{
  _name = [name copy];
  _socketType = socketType;
  _type = type;
  _connections = [NSMutableSet new];

  self.extraSpace = CGRectGetWidth(self.bounds) - CGRectGetWidth(self.label.bounds);

  self.label.text = [_name uppercaseString];
  self.socketButton.adjustsImageWhenDisabled = NO;
  self.socketButton.adjustsImageWhenHighlighted = NO;
  self.socketButton.enabled = NO;

  [self sizeToFit];
}

- (void)addConnectionToSocket:(KZNSocket *)inputSocket
{
  NSParameterAssert(inputSocket.socketType == KZNNodeSocketTypeInput);
  NSParameterAssert(self.socketType == KZNNodeSocketTypeOutput);

  if (inputSocket.socketType == KZNNodeSocketTypeInput) {
    [(NSMutableSet *)self.connections addObject:inputSocket];
    inputSocket.sourceSocket = self;
  }
}

- (void)removeConnectionToSocket:(KZNSocket *)inputSocket
{
  NSParameterAssert(inputSocket.socketType == KZNNodeSocketTypeInput);
  [(NSMutableSet *)self.connections removeObject:inputSocket];
  inputSocket.sourceSocket = nil;
}


- (void)setSourceSocket:(KZNSocket *)sourceSocket
{
  NSParameterAssert(self.socketType == KZNNodeSocketTypeInput);
  NSParameterAssert(!sourceSocket || sourceSocket.socketType == KZNNodeSocketTypeOutput);

  [(NSMutableSet *)self.connections removeAllObjects];
  if (sourceSocket) {
    [(NSMutableSet *)self.connections addObject:sourceSocket];
  }

  [UIView transitionWithView:self.socketButton.imageView duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
    BOOL connected = sourceSocket != nil;
    self.socketButton.selected = connected;
    self.socketButton.enabled = connected;
  } completion:nil];
}

- (IBAction)pressedSocket:(id)sender
{
  [self.parent.workspace pressedSocket:self];
}

- (KZNSocket *)sourceSocket
{
  NSParameterAssert(self.socketType == KZNNodeSocketTypeInput);
  NSParameterAssert([self.connections count] <= 1);
  return [self.connections anyObject];
}

- (CGPoint)socketCenter
{
  return self.socketButton.center;
}

- (BOOL)canConnectToSocket:(KZNSocket *)other
{
  if (self.socketType != KZNNodeSocketTypeOutput || other.socketType != KZNNodeSocketTypeInput) {
    return NO;
  }

  Class curClass = self.type;
  while (curClass) {
    if (curClass == other.type) {
      return YES;
    }
    curClass = curClass.superclass;
  }

  return NO;
}

- (void)setCompatible:(BOOL)isCompatible
{
  [UIView transitionWithView:self.socketButton.imageView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
    self.socketButton.imageView.alpha = isCompatible ? 1.0f : 0.1f;
  } completion:nil];
}


- (CGSize)sizeThatFits:(CGSize)size
{
  CGSize labelSize = [self.label sizeThatFits:size];
  labelSize.width += self.extraSpace;
  CGSize s = [super sizeThatFits:size];
  s.width = labelSize.width;
  return s;
}

@end