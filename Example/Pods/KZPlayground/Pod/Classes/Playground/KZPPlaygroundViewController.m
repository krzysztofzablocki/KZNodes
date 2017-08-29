//
//  Created by Krzysztof Zabłocki(http://twitter.com/merowing_) on 19/10/14.
//
//
//


#import <objc/runtime.h>
#import <KZPlayground/KZPPlaygroundViewController.h>
#import "KZPTimelineViewController.h"
#import "KZPPlayground+Internal.h"
#import "KZNWorkspace.h"

@interface KZPPlaygroundViewController ()
@property(weak, nonatomic) IBOutlet UIView *timelineContainerView;
@property(weak, nonatomic) IBOutlet UIView *worksheetContainerView;
@property(strong, nonatomic) KZPPlayground *currentPlayground;
@property(unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *leadingTimelineConstraint;

@property (nonatomic, assign) KZNWorkspace *workspace;
@end

@implementation KZPPlaygroundViewController

+ (KZPPlaygroundViewController *)playgroundViewController
{
  return [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle bundleForClass:self]] instantiateInitialViewController];
}

- (void)setTimelineHidden:(BOOL)hidden
{
  _timelineHidden = hidden;

  if ([self isViewLoaded]) {
    if (hidden) {
      self.leadingTimelineConstraint.constant = -CGRectGetWidth(self.timelineContainerView.bounds);
    } else {
      self.leadingTimelineConstraint.constant = 0;
    }
    [self.view layoutIfNeeded];
  }
}


- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:KZPPlaygroundDidChangeImplementationNotification object:nil];
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playgroundImplementationChanged) name:KZPPlaygroundDidChangeImplementationNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [KZPTimelineViewController setSharedInstance:self.timelineViewController];
    self.timelineHidden = self.timelineHidden;
    self.currentPlayground = [self createActivePlayground];
    [self.timelineViewController playgroundSetupCompleted];
    [self executePlayground];
      
      [self addStoregeButtons];
  });
}

- (KZPPlayground *)createActivePlayground
{
  NSArray *playgrounds = [self findClassesConformingToProtocol:@protocol(KZPActivePlayground)];
  NSAssert(playgrounds.count == 1, @"One KZPPlayground subclass needs to conform to KZPActivePlayground, it will be the active playground for the current run.");
  KZPPlayground *playground = (KZPPlayground *)[playgrounds.firstObject new];
  NSAssert([playground isKindOfClass:KZPPlayground.class], @"Class conforming to KZPActivePlayground has to be a subclass of KZPPlayground.");
  return playground;
}

- (void)reset
{
  self.currentPlayground.worksheetView = [self cleanWorksheet];
  self.currentPlayground.viewController = self;
  self.currentPlayground.playgroundViewController = self;
  [self.currentPlayground.transientObjects removeAllObjects];
  [self dismissViewControllerAnimated:NO completion:nil];

  [self.timelineViewController reset];
  [[self findClassesConformingToProtocol:@protocol(KZPComponent)] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    [obj reset];
  }];
}

- (UIView *)cleanWorksheet
{
  [self.worksheetContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  UIView *worksheetView = [[UIView alloc] initWithFrame:self.worksheetContainerView.bounds];
  worksheetView.clipsToBounds = YES;
  worksheetView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  worksheetView.backgroundColor = UIColor.lightGrayColor;
  [self.worksheetContainerView addSubview:worksheetView];
  return worksheetView;
}

- (void)executePlayground
{
  [self reset];
  _workspace = [self.currentPlayground run];
  [self playgroundDidRun];
}

- (void)playgroundDidRun
{
  [self.timelineViewController playgroundDidRun];
}

- (void)playgroundImplementationChanged
{
  [self setNeedsExecutePlayground];
}

- (void)setNeedsExecutePlayground
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(executePlayground) object:nil];
  [self performSelector:@selector(executePlayground) withObject:nil afterDelay:0];
}

#pragma mark - Helpers

- (NSArray *)findClassesConformingToProtocol:(Protocol *)protocol
{
  int numberOfClasses = objc_getClassList(NULL, 0);
  Class *classes;

  classes = (Class *)malloc(sizeof(Class) * numberOfClasses);
  objc_getClassList(classes, numberOfClasses);

  NSMutableArray *conformingClasses = [NSMutableArray array];
  for (NSInteger i = 0; i < numberOfClasses; i++) {
    Class lClass = classes[i];
    if (class_conformsToProtocol(lClass, protocol)) {
      [conformingClasses addObject:classes[i]];
    }
  }

  free(classes);
  return [conformingClasses copy];
}

- (KZPTimelineViewController *)timelineViewController
{
  return [self controllerOfClass:KZPTimelineViewController.class];
}

- (id)controllerOfClass:(Class)aClass
{
  for (UIViewController *controller in self.childViewControllers) {
    if ([controller isKindOfClass:aClass]) {
      return controller;
    }
  }

  return nil;
}

#pragma mark - Actions

- (void) addStoregeButtons {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"Save" forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(saveNodesComposition)
     forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(20.0, 20.0, 160.0, 40.0);
    [button setBackgroundColor:[UIColor redColor]];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:button];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button2 setTitle:@"Restore" forState:UIControlStateNormal];
    [button2 addTarget:self
               action:@selector(restoreNodesComposition)
     forControlEvents:UIControlEventTouchUpInside];
    button2.frame = CGRectMake(200.0, 20.0, 160.0, 40.0);
    [button2 setBackgroundColor:[UIColor redColor]];
    [button2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:button2];
}

- (void)saveNodesComposition {
    [_workspace saveNodesComposition];
}

- (void)restoreNodesComposition {
    [_workspace restoreNodesComposition];
}

@end
