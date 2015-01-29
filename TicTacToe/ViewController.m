//
//  ViewController.m
//  TicTacToe
//
//  Created by LuoLiu on 15/1/26.
//  Copyright (c) 2015年 LuoLiu. All rights reserved.
//

#import "ViewController.h"
#import "Packet.h"
#import "AlertBlock.h"

@interface ViewController ()

@property (strong, nonatomic)MCNearbyServiceAdvertiser *advertiser;
@property (strong, nonatomic)MCBrowserViewController *browserViewController;

@end

@implementation ViewController

- (void)viewDidLoad {
    _myDieRoll = kDiceNotRolled;
    self.oPieceImage = [UIImage imageNamed:@"O.png"];
    self.xPieceImage = [UIImage imageNamed:@"X.png"];
    
    if (!_peerID) {
        _peerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    }
    if (!_session) {
        _session = [[MCSession alloc] initWithPeer:_peerID];
    }
    _session.delegate = self;
    
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    _session.isAccessibilityElement = NO;
    [_session disconnect];
    _session.delegate = nil;
}

#pragma mark - Game-Specific Actions

- (IBAction)gameButtonPressed:(id)sender {
    _dieRollRecieved = NO;
    _dieRollAcknowledged = NO;
    
    _gameButton.hidden = YES;
    
    _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_peerID discoveryInfo:nil serviceType:kTicTacToeServieceType];
    _advertiser.delegate = self;
    [_advertiser startAdvertisingPeer];
    
    _browserViewController = [[MCBrowserViewController alloc] initWithServiceType:kTicTacToeServieceType session:_session];
    _browserViewController.delegate = self;
    [self presentViewController:_browserViewController animated:YES completion:nil];
}

- (IBAction)gameSpacePressed:(id)sender {
    UIButton *buttonPressed = sender;
    if (_state == kGameStateMyTurn && [buttonPressed imageForState:UIControlStateNormal] == nil) {
        [buttonPressed setImage:((_playerPiece == kPlayerPieceO) ? self.oPieceImage : self.xPieceImage) forState:UIControlStateNormal];
        _feedbackLabel.text = NSLocalizedString(@"Opponent's Turn", @"Opponent's Turn");
        _state = kGameStateYourTurn;
        
        Packet *packet = [[Packet alloc] initMovePacketWithSpace:(BoardSpace)buttonPressed.tag];
        [self sendPacket:packet];
        
        [self checkForGameEnd];
    }
}


#pragma mark - MCBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    [_browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    [_browserViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler {
    
    AlertBlock *alert = [[AlertBlock alloc]
                          initWithTitle:@"Received Invitation"
                          message:[NSString stringWithFormat:@"Received Invitation from %@", peerID.displayName]
                          delegate:self
                          cancelButtonTitle:@"No"
                          otherButtonTitles:@"Accept"
                          block:^(NSInteger buttonIndex) {
                              BOOL acceptedInvitation;

                              if (buttonIndex == 0) {
                                  [_advertiser stopAdvertisingPeer];
                                  _advertiser = nil;
                                  acceptedInvitation = NO;
                              }
                              else if (buttonIndex == 1){
                                  acceptedInvitation = YES;
                                  [_session.connectedPeers arrayByAddingObject:peerID];
                              }
                              
                              invitationHandler(acceptedInvitation, (acceptedInvitation ? _session : nil));
                          }];
    [alert show];
}

#pragma mark - MCSessionDelegate
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    NSLog(@"didChangeState");
    switch (state) {
        case MCSessionStateConnected:
            NSLog(@"Connect successful.");
            [self startNewGame];
            [_browserViewController dismissViewControllerAnimated:YES completion:nil];
            break;
        case MCSessionStateConnecting:
            NSLog(@"connecting...");
            break;
        default:
            NSLog(@"connect failed");
            break;
    }
    
    if (state == MCSessionStateNotConnected) {
        _state = kGameStateInterrupted;
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Peer Disconnected", @"Peer Disconnected")
                              message:NSLocalizedString(@"Connection lost", @"Connection lost")
                              delegate:self
                              cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                              otherButtonTitles:nil, nil];
        alert.tag = 1;
        [alert show];
        [session disconnect];
        session.delegate = nil;
        _session = nil;
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSKeyedUnarchiver *unachiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    Packet *packet = [unachiver decodeObjectForKey:kTicTacToeArchiveKey];
    
    switch (packet.type) {
        case kPacketTypeDieRoll: {
            _opponentDieRoll = packet.dieRoll;
            Packet *ack = [[Packet alloc] initAckPacketWithDieRoll:_opponentDieRoll];
            [self sendPacket:ack];
            _dieRollRecieved = YES;
            break;
        }
    
        case kPacketTypeAck: {
            if (packet.dieRoll != _myDieRoll) {
                NSLog(@"Ack packet doesn't match yourDieRoll (mine: %d, send: %d", (int)packet.dieRoll, (int)_myDieRoll);
            }
            _dieRollAcknowledged = YES;
            break;
        }
            
        case kPacketTypeMove: {
            UIButton *aButton = (UIButton *)[self.view viewWithTag:packet.space];
            _state = kGameStateMyTurn;
            
            if (aButton != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.feedbackLabel.text = NSLocalizedString(@"Your Turn", @"Your Turn");
                    [aButton setImage:((_playerPiece == kPlayerPieceO) ? self.xPieceImage : self.oPieceImage)
                             forState:UIControlStateNormal];
                    [self checkForGameEnd];
                });
            }
            break;
        }
            
        case kPacketTypeReset: {
            if (_state == kGameStateDone) {
                [self resetDieState];
            }
            break;
        }
            
        default:
            break;
    }
    if (_dieRollRecieved == YES & _dieRollAcknowledged == YES) {
        [self startGame];
    }
}


-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    
}


-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
    
}


-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
    
}


#pragma mark - UIAlertView Delegate Method

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        [self resetBoard];
        self.gameButton.hidden = NO;
    }
    
}

#pragma mark - Game Methods

- (void)startNewGame {
    [self resetBoard];
    [self sendDieRoll];
}

- (void)resetBoard {
    for (int i = kUpperLeft; i <= kLowerRight; i++) {
        UIButton *aButton = (UIButton *)[self.view viewWithTag:i];
        [aButton setImage:nil forState:UIControlStateNormal];
    }
    
    self.feedbackLabel.text = @"";
    Packet *packet = [[Packet alloc] initResetPacket];
    [self sendPacket:packet];
    _playerPiece = kPlayerPieceUndecided;
}

- (void)resetDieState {
    _dieRollRecieved = NO;
    _dieRollAcknowledged = NO;
    _myDieRoll = kDiceNotRolled;
    _opponentDieRoll = kDiceNotRolled;
}

- (void)startGame {
    if (_myDieRoll == _opponentDieRoll) {
        _myDieRoll = kDiceNotRolled;
        [self sendDieRoll];
        _playerPiece = kPlayerPieceUndecided;
    }
    else if (_myDieRoll < _opponentDieRoll) {
        _state = kGameStateYourTurn;
        _playerPiece = kPlayerPieceX;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.feedbackLabel.text = NSLocalizedString(@"Opponent's Turn", @"Opponent's Turn");
        });
        [self.view setNeedsDisplay];
    }
    else {
        _state = kGameStateMyTurn;
        _playerPiece = kPlayerPieceO;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.feedbackLabel.text = NSLocalizedString(@"Your Turn", @"Your Turn");
        });
        [self.view setNeedsDisplay];
    }
    [self resetDieState];
}

- (void)sendDieRoll {
    Packet *rollPacket;
    _state = kGameStateRollingDice;
    if (_myDieRoll == kDiceNotRolled) {
        rollPacket = [[Packet alloc] initDieRollPacket];
        _myDieRoll = rollPacket.dieRoll;
    }
    else {
        rollPacket = [[Packet alloc] initDieRollPacketWithRoll:_myDieRoll];
    }
    [self sendPacket:rollPacket];
}

- (void)sendPacket:(Packet *)packet {
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:packet forKey:kTicTacToeArchiveKey];
    [archiver finishEncoding];
    NSError *error = nil;
    NSArray *peers =  [_session connectedPeers];
    if (![_session sendData:data toPeers:peers withMode:MCSessionSendDataReliable error:&error]) {
        NSLog(@"Error sending data: %@", [error localizedDescription]);
    }
}

- (void)checkForGameEnd {
    NSInteger moves = 0;
    
    UIImage *currentButtonImages[9];
    UIImage *winningImage = nil;
    
    for (int i = kUpperLeft; i <= kLowerRight; i++) {
        UIButton *oneButton = (UIButton *)[self.view viewWithTag:i];
        if ([oneButton imageForState:UIControlStateNormal]) {
            moves++;
        }
        currentButtonImages[i - kUpperLeft] = [oneButton imageForState:UIControlStateNormal];
    }
    
    //Top Row
    if (currentButtonImages[0] == currentButtonImages[1]
        && currentButtonImages[0] == currentButtonImages[2]
        && currentButtonImages[0] != nil) {
        winningImage = currentButtonImages[0];
    }
    
    //Middle Row
    else if (currentButtonImages[3] == currentButtonImages[4]
        && currentButtonImages[3] == currentButtonImages[5]
        && currentButtonImages[3] != nil) {
        winningImage = currentButtonImages[3];
    }
    
    //Bottom Row
    else if (currentButtonImages[6] == currentButtonImages[7]
        && currentButtonImages[6] == currentButtonImages[8]
        && currentButtonImages[6] != nil) {
        winningImage = currentButtonImages[6];
    }
    
    //Top Colum
    else if (currentButtonImages[0] == currentButtonImages[3]
        && currentButtonImages[0] == currentButtonImages[6]
        && currentButtonImages[0] != nil) {
        winningImage = currentButtonImages[0];
    }
    
    //Middle Colum
    else if (currentButtonImages[1] == currentButtonImages[4]
             && currentButtonImages[1] == currentButtonImages[7]
             && currentButtonImages[1] != nil) {
        winningImage = currentButtonImages[1];
    }
    
    //Bottom Colum
    else if (currentButtonImages[2] == currentButtonImages[5]
             && currentButtonImages[2] == currentButtonImages[8]
             && currentButtonImages[2] != nil) {
        winningImage = currentButtonImages[2];
    }
    
    //Diagonal starting top left
    else if (currentButtonImages[0] == currentButtonImages[4]
             && currentButtonImages[0] == currentButtonImages[8]
             && currentButtonImages[0] != nil) {
        winningImage = currentButtonImages[0];
    }
    
    //Diagonal starting top right
    else if (currentButtonImages[2] == currentButtonImages[4]
             && currentButtonImages[2] == currentButtonImages[6]
             && currentButtonImages[2] != nil) {
        winningImage = currentButtonImages[2];
    }
    
    if (winningImage == self.xPieceImage) {
        if (_playerPiece == kPlayerPieceX) {
            self.feedbackLabel.text = NSLocalizedString(@"You win", @"You win");
        }
        else {
            self.feedbackLabel.text = NSLocalizedString(@"Opponent win", @"Opponent win");
        }
        _state = kGameStateDone;
    }
    else if (winningImage == self.oPieceImage) {
        if (_playerPiece == kPlayerPieceO) {
            self.feedbackLabel.text = NSLocalizedString(@"You win", @"You win");
        }
        else {
            self.feedbackLabel.text = NSLocalizedString(@"Opponent win", @"Opponent win");
        }
        _state = kGameStateDone;
    }
    else {
        if (moves >= 9) {
            self.feedbackLabel.text = NSLocalizedString(@"^_^", @"^_^");
            _state = kGameStateDone;
        }
    }
    
    if (_state == kGameStateDone) {
        [self performSelector:@selector(startNewGame) withObject:nil afterDelay:3.0];
    }

}

@end
