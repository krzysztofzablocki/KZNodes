//
//  Created by merowing on 29/10/14.
//
//
//


#import "KZNGridView.h"
#import "KZNNode.h"
#import "KZNSocket+Internal.h"
#import "KZNWorkspace.h"

@import ObjectiveC.runtime;

static const void *kSocketConnectionLayerKey = &kSocketConnectionLayerKey;

@interface KZNGridView ()
@property(nonatomic, weak) CAShapeLayer *overlay;
@property(nonatomic) CGPoint draggedObjectCenterOffset;
@property(nonatomic, strong) UIView *draggedObject;
@property(nonatomic, assign) CGPoint lastPanPosition;
@property(nonatomic, strong) NSMutableArray *nodes;
@property(nonatomic, weak) IBOutlet UIView *zoomableView;
@end

@implementation KZNGridView
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self) {
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:panGestureRecognizer];

    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self addGestureRecognizer:pinchGestureRecognizer];

    self.nodes = [NSMutableArray new];
  }

  return self;
}

- (CAShapeLayer *)overlay
{
  if (!_overlay) {
    CAShapeLayer *layer = [CAShapeLayer layer];
    self.overlay = layer;
    [self setupLinePropertiesForLayer:_overlay];
    [self.zoomableView.layer addSublayer:_overlay];
  }

  return _overlay;
}

- (void)setupLinePropertiesForLayer:(CAShapeLayer *)connectionLayer
{
  connectionLayer.frame = self.bounds;
  connectionLayer.zPosition = 2;
  connectionLayer.lineWidth = 2;
  connectionLayer.fillColor = UIColor.clearColor.CGColor;
  connectionLayer.strokeColor = [UIColor colorWithRed:0.49f green:0.52f blue:0.56f alpha:1.0f].CGColor;
  connectionLayer.allowsEdgeAntialiasing = YES;
  connectionLayer.lineCap = kCALineCapRound;
}

- (void)updateConnections
{
  [self.zoomableView.subviews enumerateObjectsUsingBlock:^(KZNNode *node, NSUInteger idx, BOOL *stop) {
    if (![node isKindOfClass:KZNNode.class]) {
      return;
    }

    [node.inputSockets enumerateObjectsUsingBlock:^(KZNSocket *inputSocket, NSUInteger idx, BOOL *stop) {
      if (!inputSocket.sourceSocket) {
        return;
      }
      CAShapeLayer *layer = objc_getAssociatedObject(inputSocket, kSocketConnectionLayerKey);
      [self adjustConnectionLayer:layer fromSocket:inputSocket.sourceSocket toSocket:inputSocket];
    }];
  }];
}

- (void)adjustConnectionLayer:(CAShapeLayer *)connectionLayer fromSocket:(KZNSocket *)outputSocket toSocket:(KZNSocket *)inputSocket
{
  CGPoint startPoint = [connectionLayer convertPoint:[outputSocket socketCenter] fromLayer:outputSocket.layer];
  CGPoint targetPoint = [connectionLayer convertPoint:[inputSocket socketCenter] fromLayer:inputSocket.layer];
  connectionLayer.path = [self pathFromPoint:startPoint toPoint:targetPoint];
}


- (void)setOffset:(CGPoint)offset
{
  CGFloat offsetX = _offset.x - offset.x;
  CGFloat offsetY = _offset.y - offset.y;

  _offset = offset;
  [self.zoomableView.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
    CGPoint center = subview.center;
    center.x -= offsetX;
    center.y -= offsetY;
    subview.center = center;
  }];
  [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetLineWidth(context, 0.5);
  CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0.176 green:0.184 blue:0.188 alpha:1].CGColor);

  NSInteger signOffset = 1000000;
  CGPoint offset = CGPointMake(roundf(self.offset.x - signOffset * 0.5f), roundf(self.offset.y - signOffset * 0.5f));
  CGContextTranslateCTM(context, offset.x, 0);

  CGFloat width = CGRectGetWidth(self.bounds);
  CGFloat height = CGRectGetHeight(self.bounds);

  NSUInteger numberOfColumns = (NSUInteger)floorf(width / 32);
  NSUInteger numberOfRows = (NSUInteger)floorf(height / 32);
  CGFloat columnWidth = width / (numberOfColumns + 1.0f);

  NSInteger firstColumn = (NSInteger)(-offset.x / columnWidth);
  for (int i = firstColumn; i <= firstColumn + numberOfColumns + 1; i++) {
    CGPoint startPoint;
    CGPoint endPoint;

    startPoint.x = roundf(columnWidth * i);
    startPoint.y = 0.0f;

    endPoint.x = startPoint.x;
    endPoint.y = height;

    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGFloat lengths[] = { 2.0f, 2.0f, 2.0f };
    CGContextSetLineDash(context, 5, lengths, 3);
    CGContextStrokePath(context);
  }

  CGContextTranslateCTM(context, -offset.x, offset.y);

  CGFloat rowHeight = height / (numberOfRows + 1.0f);
  NSInteger firstRow = (NSInteger)(-offset.y / rowHeight);
  for (int j = firstRow; j <= firstRow + numberOfRows; j++) {
    CGPoint startPoint;
    CGPoint endPoint;

    startPoint.x = 0.0f;
    startPoint.y = roundf(rowHeight * j);

    endPoint.x = width;
    endPoint.y = startPoint.y;

    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGContextStrokePath(context);
  }
}

- (void)prepareConnectionLayerForSocket:(KZNSocket *)inputSocket
{
  CAShapeLayer *connectionLayer = [CAShapeLayer layer];
  [self setupLinePropertiesForLayer:connectionLayer];
  [self.zoomableView.layer addSublayer:connectionLayer];
  objc_setAssociatedObject(inputSocket, kSocketConnectionLayerKey, connectionLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
  CGPoint point = [panGestureRecognizer locationInView:self.zoomableView];

  switch (panGestureRecognizer.state) {
    case UIGestureRecognizerStateBegan: {
      __block BOOL found = NO;
      [self findObjectForPoint:point completion:^(KZNSocket *obj, CGPoint offset) {
        self.draggedObject = obj;
        self.draggedObjectCenterOffset = offset;
        if ([obj isKindOfClass:KZNSocket.class]) {
          [self markCompatibleSocketsForOutputSocket:obj];
        }
        found = YES;
      }];
      if (!found) {
        self.lastPanPosition = point;
      }
    }
      break;
    case UIGestureRecognizerStateChanged: {
      if (self.draggedObject) {
        if ([self.draggedObject isKindOfClass:KZNSocket.class]) {
          CGPoint socketCenter = [self.zoomableView convertPoint:[(KZNSocket *)self.draggedObject socketCenter] fromView:self.draggedObject];
          self.overlay.path = [self pathFromPoint:socketCenter toPoint:[self convertPoint:point fromView:panGestureRecognizer.view]];
          [self updateConnections];
          return;
        }
        self.draggedObject.center = CGPointMake(self.draggedObjectCenterOffset.x + point.x, self.draggedObjectCenterOffset.y + point.y);
        [self updateConnections];
      } else {
        CGFloat offsetX = self.lastPanPosition.x - point.x;
        CGFloat offsetY = self.lastPanPosition.y - point.y;
        self.lastPanPosition = point;

        CGPoint offset = self.offset;
        offset.x -= offsetX;
        offset.y -= offsetY;
        self.offset = offset;
        [self updateConnections];
      }
    }
      break;

    case UIGestureRecognizerStateEnded: {
      [self findObjectForPoint:point completion:^(KZNSocket *inputSocket, CGPoint offset) {
        if ([self.draggedObject isKindOfClass:KZNSocket.class] && [inputSocket isKindOfClass:KZNSocket.class]) {
          BOOL canConnect = [(KZNSocket *)self.draggedObject canConnectToSocket:inputSocket];

          if (canConnect) {
            if (inputSocket.sourceSocket) {
              [self.workspace breakConnectionFromSocket:inputSocket.sourceSocket toSocket:inputSocket];
            }
            [self prepareConnectionLayerForSocket:inputSocket];
            [(KZNSocket *)self.draggedObject addConnectionToSocket:inputSocket];
            [self.workspace evaluate];
          }
        }
      }];
    }
    case UIGestureRecognizerStateCancelled: {
      self.draggedObject = nil;
      self.draggedObjectCenterOffset = CGPointZero;
      self.overlay.path = nil;
      [self updateConnections];
      [self markCompatibleSocketsForOutputSocket:nil];
    }
      break;

    default:
      break;
  }
}

- (void)markCompatibleSocketsForOutputSocket:(KZNSocket *)socket
{
  [self.nodes enumerateObjectsUsingBlock:^(KZNNode *node, NSUInteger idx, BOOL *stop) {
    if (node == socket.parent) {
      return;
    }

    [node.inputSockets enumerateObjectsUsingBlock:^(KZNSocket *inputSocket, NSUInteger idx, BOOL *stop) {
      [inputSocket setCompatible:socket ? [socket canConnectToSocket:inputSocket] : YES];
    }];
  }];
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
  CGFloat scale = pinchGestureRecognizer.scale;
  pinchGestureRecognizer.scale = 1;
  self.zoomableView.transform = CGAffineTransformScale(self.zoomableView.transform, scale, scale);
}

- (void)findObjectForPoint:(CGPoint)point completion:(void (^)(id obj, CGPoint offset))completion
{
  [[self.nodes copy] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(KZNNode *node, NSUInteger idx, BOOL *stop) {
    CGPoint localPoint = [node.layer convertPoint:point fromLayer:self.zoomableView.layer];
    KZNSocket *socket = [node socketForTouchPoint:localPoint];
    if (socket) {
      completion(socket, CGPointMake(socket.center.x - point.x, socket.center.y - point.y));
      *stop = YES;
      return;
    }

    if ([node canDragWithPoint:localPoint]) {
      completion(node, CGPointMake(node.center.x - point.x, node.center.y - point.y));
      [self.nodes removeObject:node];
      [self.nodes addObject:node];
      [self.zoomableView bringSubviewToFront:node];
      *stop = YES;
    }
  }];
}


- (CGPathRef)pathFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint
{
  //! http://stackoverflow.com/questions/8024736/how-to-compute-the-control-points-for-a-smooth-path-given-a-set-of-points
  CGMutablePathRef curvedPath = CGPathCreateMutable();
  const int TOTAL_POINTS = 3;
  int horizontalWiggle = 20;

  int stepChangeX = (int)((endPoint.x - startPoint.x) / TOTAL_POINTS);
  int stepChangeY = (int)((endPoint.y - startPoint.y) / TOTAL_POINTS);

  for (int i = 0; i < TOTAL_POINTS; i++) {
    int startX = (int)(startPoint.x + i * stepChangeX);
    int startY = (int)(startPoint.y + i * stepChangeY);

    int endX = (int)(startPoint.x + (i + 1) * stepChangeX);
    int endY = (int)(startPoint.y + (i + 1) * stepChangeY);

    int cpX1 = (int)(startPoint.x + (i + 0.25) * stepChangeX);
    if ((i + 1) % 2) {
      cpX1 -= horizontalWiggle;
    } else {
      cpX1 += horizontalWiggle;
    }
    int cpY1 = (int)(startPoint.y + (i + 0.25) * stepChangeY);

    int cpX2 = (int)(startPoint.x + (i + 0.75) * stepChangeX);
    if ((i + 1) % 2) {
      cpX2 -= horizontalWiggle;
    } else {
      cpX2 += horizontalWiggle;
    }
    int cpY2 = (int)(startPoint.y + (i + 0.75) * stepChangeY);

    CGPathMoveToPoint(curvedPath, NULL, startX, startY);
    CGPathAddCurveToPoint(curvedPath, NULL, cpX1, cpY1, cpX2, cpY2, endX, endY);
  }

  return curvedPath;
}

- (void)addNode:(KZNNode *)node
{
  [self.nodes addObject:node];
  [self.zoomableView addSubview:node];
}

- (void)removeNode:(KZNNode *)node
{
  [self.nodes removeObject:node];
  [node removeFromSuperview];
}

- (void)clearConnectionLayerForSocket:(KZNSocket *)inputSocket
{
  CALayer *layer = objc_getAssociatedObject(inputSocket, kSocketConnectionLayerKey);
  [layer removeFromSuperlayer];
}
@end