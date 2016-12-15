#import "AppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "GCDAsyncUdpSocket.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]


@implementation AppDelegate

@synthesize window = _window;
@synthesize portField;
@synthesize startStopButton;
@synthesize logView;

NSMutableArray *addressArray;
NSMutableArray *messagequeue;
bool disconnectFlag;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Setup our logging framework.
	
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    messagequeue = [[NSMutableArray alloc]init];
	udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [udpSocket setIPv4Enabled:YES];
    [udpSocket enableBroadcast:YES error:nil];
    addressArray=[[NSMutableArray alloc]init];
    disconnectFlag=FALSE;
}

- (void)awakeFromNib
{
	[logView setEnabledTextCheckingTypes:0];
	[logView setAutomaticSpellingCorrectionEnabled:NO];
}

- (void)scrollToBottom
{
	NSScrollView *scrollView = [logView enclosingScrollView];
	NSPoint newScrollOrigin;
	
	if ([[scrollView documentView] isFlipped])
		newScrollOrigin = NSMakePoint(0.0F, NSMaxY([[scrollView documentView] frame]));
	else
		newScrollOrigin = NSMakePoint(0.0F, 0.0F);
	
	[[scrollView documentView] scrollPoint:newScrollOrigin];
}

- (void)logError:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

- (void)logInfo:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor purpleColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

- (void)logMessage:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

- (IBAction)startStopButtonPressed:(id)sender
{
	if (isRunning)
	{
		// STOP udp echo server
		
		[udpSocket close];
		
		[self logInfo:@"Stopped Udp Echo server"];
		isRunning = false;
		
		[portField setEnabled:YES];
		[startStopButton setTitle:@"Start"];
	}
	else
	{
		// START udp echo server
		
		int port = 14111;
		if (port < 0 || port > 65535)
		{
			[portField setStringValue:@""];
			port = 0;
		}
		
		NSError *error = nil;
		
		if (![udpSocket bindToPort:port error:&error])
		{
			[self logError:FORMAT(@"Error starting server (bind): %@", error)];
			return;
		}
		if (![udpSocket beginReceiving:&error])
		{
			[udpSocket close];
			
			[self logError:FORMAT(@"Error starting server (recv): %@", error)];
			return;
		}
		[udpSocket enableBroadcast:YES error:&error];
		[self logInfo:FORMAT(@"Udp Echo server started on port %hu", [udpSocket localPort])];
		isRunning = YES;
		[portField setEnabled:NO];
		[startStopButton setTitle:@"Stop"];
	}
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    // You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    // You could add checks here
}
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
                                               fromAddress:(NSData *)address
                                         withFilterContext:(id)filterContext
{
    
    
    //Maven1
	NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg)
	{
		[self logMessage:msg];
	}
	else
	{
		[self logError:@"Error converting received data into UTF-8 String"];
	}


//partea server
    
    if([msg isEqual:@"GetDataFromNode2"])
    {
        NSData *data1 = [@"Data1" dataUsingEncoding:NSUTF8StringEncoding];
        [udpSocket sendData:data1 toHost:@"127.0.0.1" port:14222 withTimeout:-1 tag:0];
        
    }

    
        
    
   

    
//    [udpSocket sendData:data toHost:@"239.255.255.250" port:12222 withTimeout:-1 tag:0];
  
}

@end
