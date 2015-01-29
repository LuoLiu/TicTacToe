//
//  TicTacToe.h
//  TicTacToe
//
//  Created by LuoLiu on 15/1/26.
//  Copyright (c) 2015年 LuoLiu. All rights reserved.
//


//After ios7
#define kTicTacToeServieceType @"luoliu-service"

#define kTicTacToeSessionID @"com.luoliu.TicTacToe.session"
#define kTicTacToeArchiveKey @"com.luoliu.TicTacToe"
#define dieRoll() (arc4random() % 1000000)
#define kDiceNotRolled INT_MAX

typedef enum GameStates {
    kGameStateBeginning,
    kGameStateRollingDice,
    kGameStateMyTurn,
    kGameStateYourTurn,
    kGameStateInterrupted,
    kGameStateDone,
} GameState;

typedef enum BoardSpaces {
    kUpperLeft = 1000,
    kUpperMiddle,
    kUpperRight,
    kMiddleLeft,
    kMiddleMiddle,
    kMiddleRight,
    kLowerLeft,
    kLowerMiddle,
    kLowerRight,
} BoardSpace;

typedef enum PlayerPieces {
    kPlayerPieceUndecided,
    kPlayerPieceO,
    kPlayerPieceX,
} PlayerPiece;

typedef enum PacketTypes {
    kPacketTypeDieRoll,
    kPacketTypeAck,
    kPacketTypeMove,
    kPacketTypeReset,
} PacketType;