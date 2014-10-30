//
//  Created by merowing on 29/10/14.
//
//
//


@import Foundation;

#import "KZNSocket.h"

@interface KZNSocket ()
@property(nonatomic, weak, readwrite) KZNNode *parent;
@property(nonatomic, strong, readwrite) NSMutableSet *connections;
@property(nonatomic) CGFloat extraSpace;
@end