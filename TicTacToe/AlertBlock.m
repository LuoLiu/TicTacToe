//
//  AlertBlock.m
//  TicTacToe
//
//  Created by LuoLiu on 15/1/28.
//  Copyright (c) 2015年 LuoLiu. All rights reserved.
//

#import "AlertBlock.h"

@implementation AlertBlock

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles block:(TouchBlock)block {
    self = [super initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles, nil];
    if (self) {
        self.block = block;
    }
    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    self.block(buttonIndex);
}

@end
