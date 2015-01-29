//
//  AlertBlock.h
//  TicTacToe
//
//  Created by LuoLiu on 15/1/28.
//  Copyright (c) 2015年 LuoLiu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^TouchBlock) (NSInteger buttonIndex);

@interface AlertBlock : UIAlertView <UIAlertViewDelegate>

@property (strong, nonatomic)TouchBlock block;

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
           delegate:(id)delegate
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString *)otherButtonTitles
              block:(TouchBlock)block;

@end
