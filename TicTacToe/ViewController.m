//
//  ViewController.m
//  TicTacToe
//
//  Created by LuoLiu on 15/1/26.
//  Copyright (c) 2015年 LuoLiu. All rights reserved.
//

#import "ViewController.h"
#import "Packet.h"
typedef void (^ActionSheetBlock)(UIActionSheet *actionSheet, NSInteger buttonIndex);

@interface ViewController ()

@property (strong, nonatomic)MCNearbyServiceAdvertiser *advertiser;
@property (strong, nonatomic)MCBrowserViewController *browserViewController;

@end

@interface UIActionSheet ()

- (void)actionSheetWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelTitle destructiveButtonTitle:(NSString *)destructiveTitle otherButtonTitles:(NSString *)otherTitles block:(ActionSheetBlock)block;

@end

@implementation ViewController

- (void)viewDidLoad {
    _myDieRoll = kDiceNotRolled;
    self.oPieceImage = [UIImage imageNamed:@"O.png"];
    self.xPieceImage = [UIImage imageNamed:@"X.png"];
    
    _peerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    _session = [[MCSession alloc] initWithPeer:_peerID];
    _session.delegate = self;
    
    [super viewDidLoad];
}

#pragma mark - Game-Specific Actions

- (IBAction)gameButtonPressed:(id)sender {
    _dieRollRecieved = NO;
    _dieRollAcknowledged = NO;
    
    _gameButton.hidden = YES;
    //Afer ios7
    NSLog(@"%@, %@, %@", _peerID, _session, kTicTacToeServieceType);

    _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_peerID discoveryInfo:nil serviceType:kTicTacToeServieceType];
    _advertiser.delegate = self;
    [_advertiser startAdvertisingPeer];
    
//    MCNearbyServiceBrowser *browser = [[MCNearbyServiceBrowser alloc] initWithPeer:_peerID serviceType:kTicTacToeServieceType];
//    browser.delegate = self;
    _browserViewController = [[MCBrowserViewController alloc] initWithServiceType:kTicTacToeServieceType session:_session];
    _browserViewController.delegate = self;
    [self presentViewController:_browserViewController animated:YES completion:nil];
}

- (IBAction)gameSpacePressed:(id)sender {
    UIButton *buttonPressed = sender;
    if (_state == kGameSteteMyTurn && [buttonPressed imageForState:UIControlStateNormal] == nil) {
        [buttonPressed setImage:((_playerPiece == kPlayerPieceO) ? self.oPieceImage : self.xPieceImage) forState:UIControlStateNormal];
        _feedbackLabel.text = NSLocalizedString(@"Opponent's Turn", @"Opponent's Turn");
        _state = kGameSteteYourTurn;
        
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
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    
}

#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler {
    

    
    BOOL acceptedInvitation = YES;
    invitationHandler(acceptedInvitation, (acceptedInvitation ? _session: nil));
    

    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    [actionSheet actionSheetWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Received Invitation from %@", @"Received Invitation from {Peer}"), peerID.displayName]
                       cancelButtonTitle:NSLocalizedString(@"Reject", nil)
                  destructiveButtonTitle:nil
                       otherButtonTitles:NSLocalizedString(@"Accept", nil)
                                   block:^(UIActionSheet *actionSheet, NSInteger buttonIndex)
      {
          if (buttonIndex == [actionSheet cancelButtonIndex]) {
              self.gameButton.hidden = NO;
          }
          BOOL acceptedInvitation = (buttonIndex == [actionSheet firstOtherButtonIndex]);
          
          _session = [[MCSession alloc] initWithPeer:_peerID
                                              securityIdentity:nil
                                          encryptionPreference:MCEncryptionNone];
          _session.delegate = self;
          
          invitationHandler(acceptedInvitation, (acceptedInvitation ? _session : nil));
          UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"hello" message:@"helloworld" delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
          [alert show];
          [self startNewGame];
      }];
}

#pragma mark - MCSessionDelegate
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    NSLog(@"didChangeState");
    switch (state) {
        case MCSessionStateConnected:
            NSLog(@"Connect successful.");
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
        _state = kGameSteteInterrupted;
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Peer Disconnected", @"Peer Disconnected")
                              message:NSLocalizedString(@"Connection lost", @"Connection lost")
                              delegate:self
                              cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                              otherButtonTitles:nil, nil];
        [alert show];
        [session disconnect];
        session.delegate = nil;
        _session = nil;
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSKeyedUnarchiver *unachiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    Packet *packert = [unachiver decodeObjectForKey:kTicTacToeArchiveKey];
    
    switch (packert.type) {
        case kPacketTypeDieRoll: {
            _opponentDieRoll = packert.dieRoll;
            Packet *ack = [[Packet alloc] initAckPacketWithDieRoll:_opponentDieRoll];
            [self sendPacket:ack];
            _dieRollRecieved = YES;
            break;
        }
    
        case kPacketTypeAck: {
            if (packert.dieRoll != _myDieRoll) {
                NSLog(@"Ack packet doesn't match yourDieRoll (mine: %d, send: %d", (int)packert.dieRoll, (int)_myDieRoll);
            }
            _dieRollAcknowledged = YES;
            break;
        }
            
        case kPacketTypeMove: {
            UIButton *aButton = (UIButton *)[self.view viewWithTag:[packert space]];
            [aButton setImage:((_playerPiece == kPlayerPieceO) ? self.xPieceImage : self.oPieceImage)
                     forState:UIControlStateNormal];
            _state = kGameSteteMyTurn;
            _feedbackLabel.text = NSLocalizedString(@"Your Turn", @"Your Turn");
            [self checkForGameEnd];
            break;
        }
            
        case kPacketTypeReset: {
            if (_state == kGameSteteDone) {
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
    [self resetBoard];
    self.gameButton.hidden = NO;
}

@end
