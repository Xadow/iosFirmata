/*
 
 File: ViewController.m
 
 Abstract: User interface to display a list of discovered peripherals
 and allow the user to connect to them.
 
 
 */

#import <Foundation/Foundation.h>

#import "ViewController.h"
#import "LeDiscovery.h"
#import "LeDataService.h"
#import "DetailViewController.h"


@interface ViewController ()  <LeDiscoveryDelegate, LeServiceDelegate, UITableViewDataSource, UITableViewDelegate>

@property (retain, nonatomic) IBOutlet UITableView      *sensorsTable;
@property (retain, nonatomic) IBOutlet UIRefreshControl *refreshControl;

@property (retain, nonatomic) LeDataService             *currentlyDisplayingService;
@property (retain, nonatomic) NSMutableArray            *connectedServices;

@end

@implementation ViewController

@synthesize currentlyDisplayingService;
@synthesize connectedServices;
@synthesize sensorsTable;
@synthesize refreshControl;

#pragma mark -
#pragma mark View lifecycle
/****************************************************************************/
/*								View Lifecycle                              */
/****************************************************************************/
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackgroundNotification:) name:kDataServiceEnteredBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterForegroundNotification:) name:kDataServiceEnteredForegroundNotification object:nil];

    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    connectedServices = [NSMutableArray new];
    
    [self.refreshControl beginRefreshing];
    
    if (self.tableView.contentOffset.y == 0)
    {
        self.tableView.contentOffset = CGPointMake(0, -self.refreshControl.frame.size.height / 2);
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [[LeDiscovery sharedInstance] setPeripheralDelegate:self];
	[[LeDiscovery sharedInstance] setDiscoveryDelegate:self];

    [self reset:nil];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc 
{
    [[LeDiscovery sharedInstance] stopScanning];
    [[LeDiscovery sharedInstance] setPeripheralDelegate:nil];
	[[LeDiscovery sharedInstance] setDiscoveryDelegate:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DetailViewController *dest =[segue destinationViewController];
    
    //create new firmata to manage peripheral, and tell it to report to new page
    dest.currentFirmata = [[Firmata alloc] initWithService:currentlyDisplayingService controller:dest];
    
    //tell Discovery to that it should report to firmata when its peripheral changes status
    [[LeDiscovery sharedInstance] setPeripheralDelegate:dest.currentFirmata];
    
    [[LeDiscovery sharedInstance] stopScanning];
}

- (void)reset:(id)sender
{
    [[LeDiscovery sharedInstance] startScanningForUUIDString:nil];
}


#pragma mark -
#pragma mark LeData Interactions
/****************************************************************************/
/*                  LeData Interactions                                     */
/****************************************************************************/
- (LeDataService*) serviceForPeripheral:(CBPeripheral *)peripheral
{
    for (LeDataService *service in connectedServices) {
        if ( [[service peripheral] isEqual:peripheral] ) {
            return service;
        }
    }
    
    return nil;
}

- (void)didEnterBackgroundNotification:(NSNotification*)notification
{   
    NSLog(@"Entered background notification called.");
    for (LeDataService *service in self.connectedServices) {
        [service enteredBackground];
    }
}

- (void)didEnterForegroundNotification:(NSNotification*)notification
{
    NSLog(@"Entered foreground notification called.");
    for (LeDataService *service in self.connectedServices) {
        [service enteredForeground];
    }    
}

#pragma mark -
#pragma mark LeDataProtocol Delegate Methods
/****************************************************************************/
/*				LeDataProtocol Delegate Methods                             */
/****************************************************************************/
/** Received data */
- (void) serviceDidReceiveData:(NSData*)data fromService:(LeDataService*)service
{
}


#pragma mark -
#pragma mark LeDiscovery Delegate Methods
/****************************************************************************/
/*				LeDiscovery Delegate Methods                                */
/****************************************************************************/
- (void) serviceDidReceiveCharacteristicsFromService:(LeDataService*)service
{
    //Consider successfully connected, add to connected services
    NSLog(@"Service (%@) did receive characteristics", service.peripheral.name);
    if (![connectedServices containsObject:service]) {
        [connectedServices addObject:service];
    }
    
    //Segue
    currentlyDisplayingService = service;
    [self performSegueWithIdentifier: @"deviceView" sender:self];
}

/** Peripheral connected or disconnected */
- (void) serviceDidChangeStatus:(LeDataService*)service
{
    if ( ![[service peripheral] isConnected] ) {
        NSLog(@"Service (%@) disconnected", service.peripheral.name);
        if ([connectedServices containsObject:service]) {
            [connectedServices removeObject:service];
        }
    }
}

/** Central Manager reset */
- (void) serviceDidReset
{
    [connectedServices removeAllObjects];
}


#pragma mark -
#pragma mark TableView Delegates
/****************************************************************************/
/*							TableView Delegates								*/
/****************************************************************************/
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell	*cell;
	CBPeripheral	*peripheral;
	NSArray			*devices;
	NSInteger		row	= [indexPath row];
    static NSString *cellID = @"DeviceList";
    
	cell = [tableView dequeueReusableCellWithIdentifier:cellID];
	if (!cell)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID] ;
    
    //2 sections, connected devices and discovered devices
	if ([indexPath section] == 0) {
		devices = [[LeDiscovery sharedInstance] connectedServices];
        peripheral = [(LeDataService*)[devices objectAtIndex:row] peripheral];
        
	} else {
		devices = [[LeDiscovery sharedInstance] foundPeripherals];
        peripheral = (CBPeripheral*)[devices objectAtIndex:row];
	}
    
    if ([[peripheral name] length]){
        [[cell textLabel] setText:[peripheral name]];
    }
    else {
        [[cell textLabel] setText:@"Peripheral"];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if([peripheral isConnected]){
        [[cell detailTextLabel] setText:@"Connected"];
    }else {
        [[cell detailTextLabel] setText:@"Not Connected"];
    }
    
	return cell;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger	res = 0;
    
	if (section == 0)
		res = [[[LeDiscovery sharedInstance] connectedServices] count];
	else
		res = [[[LeDiscovery sharedInstance] foundPeripherals] count];
    
	return res;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	CBPeripheral	*peripheral;
	NSArray			*devices;
	NSInteger		row	= [indexPath row];
	
	if ([indexPath section] == 0)
    {
		devices = [[LeDiscovery sharedInstance] connectedServices];
        peripheral = [(LeDataService*)[devices objectAtIndex:row] peripheral];

        //if connected, segue
        if([self serviceForPeripheral:peripheral])
        {
            currentlyDisplayingService = [self serviceForPeripheral:peripheral];
            [self performSegueWithIdentifier: @"deviceView" sender:self];
        }

	} else
    {
        //found devices, send off connect which will segue if successful
		devices = [[LeDiscovery sharedInstance] foundPeripherals];
    	peripheral = (CBPeripheral*)[devices objectAtIndex:row];
        [[LeDiscovery sharedInstance] connectPeripheral:peripheral];
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{

    CBPeripheral	*peripheral;
	NSArray			*devices;
 
    //if device isnt connected we get bounds exception for array
    @try
    {
        devices = [[LeDiscovery sharedInstance] connectedServices];
        peripheral = [(LeDataService*)[devices objectAtIndex:indexPath.row] peripheral];

        if([peripheral isConnected]){
            return YES;
        }else{
            return NO;
        }
    }
    @catch(NSException* ex)
    {
        return NO;
    }

}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBPeripheral	*peripheral;
	NSArray			*devices;
    devices = [[LeDiscovery sharedInstance] connectedServices];
    peripheral = [(LeDataService*)[devices objectAtIndex:indexPath.row] peripheral];
    
    [[LeDiscovery sharedInstance] disconnectPeripheral:peripheral];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"disconnect";
}


#pragma mark -
#pragma mark LeDiscoveryDelegate 
/****************************************************************************/
/*                       LeDiscoveryDelegate Methods                        */
/****************************************************************************/
- (void) discoveryDidRefresh 
{
    [sensorsTable reloadData];
}

- (void) discoveryStatePoweredOff 
{
    NSString *title     = @"Bluetooth Power";
    NSString *message   = @"You must turn on Bluetooth in Settings in order to use LE";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

@end
