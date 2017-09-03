//
//  KZPlaygroundExample.m
//  //! TODO: persistance and loading from string

//  Created by Krzysztof Zabłocki on 19/10/2014.
//  Copyright (c) 2014 pixle. All rights reserved.
//

#import <objc/runtime.h>
#import "KZPlaygroundExample.h"
#import "KZPPlayground+Internal.h"
#import "KZNNodeType.h"
#import "KZNNodeWithSlider.h"
#import "KZNWorkspace.h"
#import "KZNNodeWithText.h"

@import SceneKit;

@interface KZPlaygroundExample()
@property (nonatomic, strong) KZNWorkspace *workspace;
@end

@implementation KZPlaygroundExample
- (void)setup
{

}

- (void)run
{
  self.playgroundViewController.timelineHidden = YES;
  [[KZNNodeType nodeTypes] removeAllObjects];

  [self addStoregeButtonsToViewController:self.playgroundViewController];

  //[self transformationWorkspace];
  [self coreImageWorkspace];
}

- (void)coreImageWorkspace
{
  [@[ @"CIPhotoEffectChrome",
    @"CIPhotoEffectFade",
    @"CIPhotoEffectInstant",
    @"CIPhotoEffectMono",
    @"CIPhotoEffectNoir",
    @"CIPhotoEffectProcess",
    @"CIPhotoEffectTonal",
    @"CIPhotoEffectTransfer" ] enumerateObjectsUsingBlock:^(NSString *filterName, NSUInteger idx, BOOL *stop) {
    NSString *name = [filterName substringFromIndex:@"CIPhotoEffect".length];
    [KZNNodeType registerType:name inputs:@{ @"Image" : CIImage.class } outputs:@{ @"Output" : CIImage.class } processingBlock:^(id node, NSDictionary *inputs, NSMutableDictionary *outputs) {
      CIImage *image = inputs[@"Image"];
      if (!image) {
        return;
      }

      CIFilter *filter = [CIFilter filterWithName:filterName
                                   keysAndValues:kCIInputImageKey, image, nil];
      CIImage *outputImage = [filter outputImage];
      outputs[@"Output"] = outputImage;
    }];
  }];

  [KZNNodeType registerType:@"slider" withClass:KZNNodeWithSlider.class inputs:nil outputs:@{ @"Output" : NSNumber.class } processingBlock:^(KZNNodeWithSlider *node, NSDictionary *inputs, NSMutableDictionary *outputs) {
    outputs[@"Output"] = @(node.slider.value);
  }].nodeSetup = ^(KZNNodeWithSlider *node){
    node.slider.continuous = NO;
  };

  [KZNNodeType registerType:@"image" withClass:KZNNodeWithText.class inputs:nil outputs:@{ @"Image" : CIImage.class } processingBlock:^(KZNNodeWithText *node, NSDictionary *inputs, NSMutableDictionary *outputs) {
    UIImage *image = [UIImage imageNamed:node.textField.text];
    if (image) {
      outputs[@"Image"] = [CIImage imageWithCGImage:image.CGImage];
    }
  }];

  [KZNNodeType registerType:@"sepia" inputs:@{ @"Image" : CIImage.class, @"Intensity" : NSNumber.class } outputs:@{ @"Output" : CIImage.class } processingBlock:^(KZNNodeWithText *node, NSDictionary *inputs, NSMutableDictionary *outputs) {
    CIImage *image = inputs[@"Image"];
    NSNumber *intensity = inputs[@"Intensity"] ?: @(0.8f);
    if (!image) {
      return;
    }

    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"
                                 keysAndValues:kCIInputImageKey, image,
                                               @"inputIntensity", intensity, nil];
    CIImage *outputImage = [filter outputImage];
    outputs[@"Output"] = outputImage;
  }];


  _workspace = [KZNWorkspace workspaceWithBounds:self.worksheetView.bounds];

  UIImageView *imageView = [[UIImageView alloc] initWithFrame:_workspace.previewView.bounds];
  [KZNNodeType registerType:@"Display" inputs:@{ @"Image" : CIImage.class } outputs:nil processingBlock:^(id node, NSDictionary *inputs, NSMutableDictionary *outputs) {
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef img = [context createCGImage:inputs[@"Image"] fromRect:[inputs[@"Image"] extent]];
    imageView.image = [UIImage imageWithCGImage:img];
    CGImageRelease(img);
  }];

  [self.worksheetView addSubview:_workspace];
  [_workspace.previewView addSubview:imageView];
}

- (void)transformationWorkspace
{
  [KZNNodeType registerType:@"slider" withClass:KZNNodeWithSlider.class inputs:@{ } outputs:@{ @"Output" : NSNumber.class } processingBlock:^(KZNNodeWithSlider *node, NSDictionary *inputs, NSMutableDictionary *outputs) {
    outputs[@"Output"] = @(node.slider.value);
  }];

  static CFTimeInterval initialTime;
  initialTime = CACurrentMediaTime();
  [KZNNodeType registerType:@"time" inputs:@{ } outputs:@{ @"Output" : NSNumber.class } processingBlock:^(KZNNode *node, NSDictionary *inputs, NSMutableDictionary *outputs) {
    outputs[@"Output"] = @(CACurrentMediaTime() - initialTime);
  }].evaluationMode = KZNEvaluationModeContinuous;

  [KZNNodeType registerType:@"sqrtf" inputs:@{ @"Input" : NSNumber.class } outputs:@{ @"Output" : NSNumber.class } processingBlock:^(KZNNode *node, NSDictionary *inputs, NSMutableDictionary *outputs) {
    outputs[@"Output"] = @(sqrtf([inputs[@"Input"] floatValue]));
  }];

  [KZNNodeType registerType:@"number" withClass:KZNNodeWithText.class inputs:nil outputs:@{ @"Output" : NSNumber.class } processingBlock:^(KZNNodeWithText *node, NSDictionary *inputs, NSMutableDictionary *outputs) {
    outputs[@"Output"] = @([node.textField.text floatValue]);
  }];

  [KZNNodeType registerType:@"multiply" inputs:@{ @"X" : NSNumber.class, @"Y" : NSNumber.class } outputs:@{ @"X * Y" : NSNumber.class } processingBlock:^(KZNNode *node, NSDictionary *inputs, NSMutableDictionary *outputs) {
    outputs[@"X * Y"] = @([inputs[@"X"] floatValue] * [inputs[@"Y"] floatValue]);
  }];

  [KZNNodeType registerType:@"trigonometry" inputs:@{ @"X" : NSNumber.class } outputs:@{ @"sin(x)" : NSNumber.class, @"cos(x)" : NSNumber.class } processingBlock:^(KZNNode *node, NSDictionary *inputs, NSMutableDictionary *outputs) {
    outputs[@"sin(x)"] = @(sin([inputs[@"X"] floatValue]));
    outputs[@"cos(x)"] = @(cos([inputs[@"X"] floatValue]));
  }];

  _workspace = [KZNWorkspace workspaceWithBounds:CGRectMake(0, 0, 1024, 768)];

  SCNNode *model = [self addSceneKitToView:_workspace.previewView];
  [KZNNodeType registerType:@"Model" inputs:@{ @"scaleX" : NSNumber.class, @"scaleY" : NSNumber.class, @"scaleZ" : NSNumber.class, @"angle" : NSNumber.class } outputs:nil processingBlock:^(id node, NSDictionary *inputs, NSMutableDictionary *outputs) {
    float angle = [inputs[@"angle"] floatValue];
    float scaleX = inputs[@"scaleX"] ? [inputs[@"scaleX"] floatValue] : 1;
    float scaleY = inputs[@"scaleY"] ? [inputs[@"scaleY"] floatValue] : 1;
    float scaleZ = inputs[@"scaleZ"] ? [inputs[@"scaleZ"] floatValue] : 1;

    model.transform = SCNMatrix4Scale(SCNMatrix4MakeRotation(angle, 0, 1, 0), scaleX, scaleY, scaleZ);
  }];

  [self.worksheetView addSubview:_workspace];
}

- (SCNNode *)addSceneKitToView:(UIView *)view
{
  SCNView *sceneView = [[SCNView alloc] initWithFrame:view.bounds];
  [view addSubview:sceneView];

  // An empty scene
  SCNScene *scene = [SCNScene scene];
  sceneView.scene = scene;

// A camera
  SCNNode *cameraNode = [SCNNode node];
  cameraNode.camera = [SCNCamera camera];

  cameraNode.transform = SCNMatrix4Rotate(SCNMatrix4MakeTranslation(2, 1, 30),
    -M_PI / 7.0,
    1, 0, 0);

  [scene.rootNode addChildNode:cameraNode];

// A spotlight
  SCNLight *spotLight = [SCNLight light];
  spotLight.type = SCNLightTypeSpot;
  spotLight.color = [UIColor redColor];
  SCNNode *spotLightNode = [SCNNode node];
  spotLightNode.light = spotLight;
  spotLightNode.position = SCNVector3Make(-2, 1, 0);

  [cameraNode addChildNode:spotLightNode];

// A square box
  CGFloat boxSide = 10.0;
  SCNBox *box = [SCNBox boxWithWidth:boxSide
                        height:boxSide
                        length:boxSide
                        chamferRadius:0];
  SCNNode *boxNode = [SCNNode nodeWithGeometry:box];
  boxNode.transform = SCNMatrix4MakeRotation(M_PI_2 / 3, 0, 1, 0);
  [scene.rootNode addChildNode:boxNode];
  return boxNode;
}

- (void)registerStringify
{
  [KZNNodeType registerType:@"Stringify" inputs:@{ @"Float" : NSNumber.class, @"Fractions" : NSNumber.class } outputs:@{ @"Output" : NSString.class } processingBlock:^(KZNNode *node, NSDictionary *inputs, NSMutableDictionary *outputs) {
    NSNumber *fractions = inputs[@"Fractions"];
    NSNumber *value = inputs[@"Float"];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.minimumFractionDigits = (NSUInteger)(fractions ? [fractions unsignedIntegerValue] : 2);
    formatter.maximumFractionDigits = formatter.minimumFractionDigits;
    outputs[@"Output"] = value ? [formatter stringFromNumber:value] : @"None";
  }];
}

- (void)addDisplayToView:(UIView *)view
{
  UILabel *displayLabel = [UILabel new];
  displayLabel.text = @"None";
  displayLabel.font = [UIFont systemFontOfSize:32];
  displayLabel.textColor = UIColor.redColor;
  [displayLabel sizeToFit];

  [KZNNodeType registerType:@"Display" withBuilder:^(KZNNodeType *type) {
    [type addSocket:KZNNodeSocketTypeInput name:@"Input" type:NSObject.class];

    type.processingBlock = ^(id node, NSDictionary *inputs, NSMutableDictionary *outputs) {
      id input = inputs[@"Input"];
      NSString *value = @"Unsupported";
      if ([input isKindOfClass:NSString.class]) {
        value = input;
      } else if ([input respondsToSelector:@selector(stringValue)]) {
        value = [input stringValue];
      }
      displayLabel.text = input ? value : @"None";
      [displayLabel sizeToFit];
    };
  }];

  displayLabel.center = CGPointMake(CGRectGetWidth(view.bounds) * 0.5f, CGRectGetHeight(view.bounds) * 0.5f);
  [view addSubview:displayLabel];
}

#pragma mark - Actions

- (void) addStoregeButtonsToViewController:(UIViewController*)vc {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setTitle:@"Save" forState:UIControlStateNormal];
  [button addTarget:self
             action:@selector(saveNodesComposition)
   forControlEvents:UIControlEventTouchUpInside];
  button.frame = CGRectMake(20.0, 20.0, 160.0, 40.0);
  [button setBackgroundColor:[UIColor redColor]];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [vc.view addSubview:button];

  UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
  [button2 setTitle:@"Restore" forState:UIControlStateNormal];
  [button2 addTarget:self
              action:@selector(restoreNodesComposition)
    forControlEvents:UIControlEventTouchUpInside];
  button2.frame = CGRectMake(200.0, 20.0, 160.0, 40.0);
  [button2 setBackgroundColor:[UIColor redColor]];
  [button2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [vc.view addSubview:button2];
}

- (void)saveNodesComposition {
  NSArray* serializedObjects = [_workspace arrayWithNodesComposition];
  [[NSUserDefaults standardUserDefaults] setObject:serializedObjects forKey:@"nodesSavedArray"];
}

- (void)restoreNodesComposition {
  NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
  NSArray *savedArray = [currentDefaults objectForKey:@"nodesSavedArray"];

  [_workspace restoreNodesCompositionFrom:savedArray removeNodesFromGrid:YES];
}
@end
