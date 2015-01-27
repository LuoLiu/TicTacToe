//
//  ViewController.h
//  TicTacToe
//
//  Created by LuoLiu on 15/1/26.
//  Copyright (c) 2015年 LuoLiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "TicTacToe.h"
@class Packet;

@interface ViewController : UIViewController <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCBrowserViewControllerDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
    GameState _state;
    NSInteger _myDieRoll;
    NSInteger _opponentDieRoll;
    BOOL _dieRollRecieved;
    BOOL _dieRollAcknowledged;
    PlayerPiece _playerPiece;
}

@property (nonatomic, strong) MCSession *session;
//@property (nonatomic, strong) NSString *peerID;
// After ios7
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) UIImage *xPieceImage;
@property (nonatomic, strong) UIImage *oPieceImage;

@property (weak, nonatomic) IBOutlet UILabel *feedbackLabel;
@property (weak, nonatomic) IBOutlet UIButton *gameButton;

- (void)resetBoard;
- (void)startNewGame;
- (void)resetDieState;
- (void)startGame;
- (void)sendPacket:(Packet *)packet;
- (void)sendDieRoll;
- (void)checkForGameEnd;

- (IBAction)gameButtonPressed:(id)sender;
- (IBAction)gameSpacePressed:(id)sender;

@end
