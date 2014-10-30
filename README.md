# KZNodes - editors like Origami made easy.

[![Version](https://img.shields.io/cocoapods/v/KZNodes.svg?style=flat)](http://cocoadocs.org/docsets/KZNodes)
[![License](https://img.shields.io/cocoapods/l/KZNodes.svg?style=flat)](http://cocoadocs.org/docsets/KZNodes)
[![Platform](https://img.shields.io/cocoapods/p/KZNodes.svg?style=flat)](http://cocoadocs.org/docsets/KZNodes)

[Watch demo](https://vimeo.com/110467626)

[![](/Screenshots/transforms.gif?raw=true)](https://vimeo.com/110467626)
[![](/Screenshots/coreimage.gif?raw=true)](https://vimeo.com/110467626)

Have you ever wondered how you could create an editor like Origami?
How about creating a subset of Origami in less than 100 lines of code?

Joining nodes is like functional programming, only visual.

Features:
- Domain agnostic, can be used to create editors for:
  - Animations
  - 3D Graphics
  - Image processing
  - Data Processing
  - Artificial Inteligence
  - Anything that you can express as a data / function pipeline?
- Sockets have data types, you specify what classes are supported, that way you never get unsupported connections.
- Fully native with 0 dependencies
- Slick looking out of the box
- Ultra simple to create new node classes, want to add class that can be used to apply sqrtf to it's input? 3 lines of code.



## NodeType creation
Think of NodeTypes like objc classes, they define common behaviour for all instances.
You can create a new node class as follows:

```objc
[KZNNodeType registerType:@"sqrtf" inputs:@{ @"Input" : NSNumber.class } outputs:@{ @"Output" : NSNumber.class } processingBlock:^(KZNNode *node, NSDictionary *inputs, NSMutableDictionary *outputs) {
    outputs[@"Output"] = @(sqrtf([inputs[@"Input"] floatValue]));
  }];
```

- sqrtf is the name
- it has input socket "Input" that accepts NSNumbers
- it has output socket "Output" that generates NSNumbers
- `Output = sqrtf(input)`

There are also 2 more advanced creator functions:

1. KZNNodeType withClass allows you to change base class used for a node, eg. use node with slider.
2. KZNNodeType withBuilder allows you to use builder pattern instead of simplified syntax.

### Setup block
You can also add setup block which will allow you to further configure new instances of your NodeType, eg. disable continuous slider.

## Node evaluation mode
Nodes are lazy evaluated by default, they will only evaluate when there is a change on their sockets or connected nodes.
Changes propagate to connections, so if you modify a node in the beginning of a graph it will propagate to all connected nodes.

If you mark node type to use continuous evaluation, it will evaluate 60 times per second if possible, eg. time node in sample app.

## Built-in node classes
### KZNNodeWithSlider
![](/Screenshots/slider.png?raw=true)

### KZNNodeWithText
![](/Screenshots/textfield.png?raw=true)

## Adding new node classes

It's simple:

1. Create a subclass of KZNNode
2. Do whatever you want with it
3. when you register Node type you can specify your class as baseClass, and reference it in processingBlock.



# Installation and setup
KZNodes is distributed as a [CocoaPod](http://cocoapods.org):
`pod 'KZNodes'`
so you can either add it to your existing project or clone this repository and play with it.

## Roadmap & Contributing

- Serialization of workspaces.
- Idiot-proofing.
- Lazy evaluation of sockets.

Pull-requests are welcomed.

It took me around 18h to get from idea to release so the code is likely to change before 1.0 release.

If you'd like to get specific features [I'm available for iOS consulting](http://www.merowing.info/about/).

## Changelog
 
### 0.1.0
- initial release
 
## License

KZNodes is available under the MIT license. See the LICENSE file for more info.

## Author

Krzysztof Zablocki, krzysztof.zablocki@pixle.pl

[Follow me on twitter.](http://twitter.com/merowing_)

[Check-out my blog](http://merowing.info) or [GitHub profile](https://github.com/krzysztofzablocki) for more cool stuff.
