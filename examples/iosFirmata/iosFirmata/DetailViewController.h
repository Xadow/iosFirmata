//
//  DetailViewController.h
//  TemperatureSensor
//
//  Created by Jacob on 11/11/13.
//  Copyright (c) 2013 Apple Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LeDataService.h"
#import "Firmata.h"

@interface DetailViewController : UITableViewController  <FirmataProtocol, UIActionSheetDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UILabel          *currentlyConnectedSensor;
@property (retain, nonatomic) IBOutlet UITableView      *pinsTable;
@property (strong, nonatomic) IBOutlet UILabel          *firmwareVersion;
@property (strong, nonatomic) IBOutlet UITextField      *stringToSend;
@property (weak, nonatomic)   IBOutlet UIBarButtonItem  *refreshButton;

@property (strong, nonatomic) Firmata                   *currentFirmata;
@property (retain, nonatomic) NSMutableArray            *pinsArray;
@property (retain, nonatomic) NSMutableDictionary       *analogMapping;
@property UITapGestureRecognizer                        *tap;

@property int                                           refreshCounter;

-(IBAction)refresh:(id)sender;
-(IBAction)sendString:(id)sender;
-(IBAction)textFieldDidBeginEditing:(UITextField *)textField;
-(IBAction)textFieldDidEndEditing:(UITextField *)textField;
@end