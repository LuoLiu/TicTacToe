//
//  Packet.h
//  TicTacToe
//
//  Created by LuoLiu on 15/1/26.
//  Copyright (c) 2015年 LuoLiu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TicTacToe.h"

@interface Packet : NSObject <NSCoding>

@property (nonatomic) PacketType type;
@property (nonatomic) NSUInteger dieRoll;
@property (nonatomic) BoardSpace space;

- (id)initWithType:(PacketType)aPacketType dieRoll:(NSUInteger)aDieRoll space:(BoardSpace)aBoardSpace;
- (id)initDieRollPacket;
- (id)initDieRollPacketWithRoll:(NSUInteger)aDieRoll;
- (id)initMovePacketWithSpace:(BoardSpace)aBoardSpace;
- (id)initAckPacketWithDieRoll:(NSUInteger)aDieRoll;
- (id)initResetPacket;

@end
