#import "ViewController.h"
#import "GCDAsyncUdpSocket.h"
#import "DDLog.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@interface ViewController ()
{
	long tag;
	GCDAsyncUdpSocket *udpSocket;
	NSMutableString *log;
}

@end


@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		log = [[NSMutableString alloc] init];
	}
	return self;
}

- (void)setupSocket
{
	udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [udpSocket setIPv4Enabled:YES];
    [udpSocket setIPv6Enabled:YES];

	NSError *error = nil;
	
	if (![udpSocket bindToPort:0 error:&error])
	{
		[self logError:FORMAT(@"Error binding: %@", error)];
		return;
	}

	if (![udpSocket beginReceiving:&error])
	{
		[self logError:FORMAT(@"Error receiving: %@", error)];
		return;
	}
    
    DDLogVerbose(@"Ready");
	[self logInfo:@"Ready"];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if (udpSocket == nil)
	{
		[self setupSocket];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(keyboardWillShow:)
	                                             name:UIKeyboardWillShowNotification 
	                                           object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(keyboardWillHide:)
	                                             name:UIKeyboardWillHideNotification
	                                           object:nil];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)getKeyboardHeight:(float *)keyboardHeightPtr
        animationDuration:(double *)animationDurationPtr
                     from:(NSNotification *)notification
{
	float keyboardHeight;
	double animationDuration;
	
	// UIKeyboardCenterBeginUserInfoKey:
	// The key for an NSValue object containing a CGRect
	// that identifies the start frame of the keyboard in screen coordinates.
	
	CGRect beginRect = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	CGRect endRect   = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
	{
		keyboardHeight = ABS(beginRect.origin.x - endRect.origin.x);
	}
	else
	{
		keyboardHeight = ABS(beginRect.origin.y - endRect.origin.y);
	}
	
	// UIKeyboardAnimationDurationUserInfoKey
	// The key for an NSValue object containing a double that identifies the duration of the animation in seconds.
	
	animationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	
	if (keyboardHeightPtr) *keyboardHeightPtr = keyboardHeight;
	if (animationDurationPtr) *animationDurationPtr = animationDuration;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
	float keyboardHeight = 0.0F;
	double animationDuration = 0.0;
	
	[self getKeyboardHeight:&keyboardHeight animationDuration:&animationDuration from:notification];
	
	CGRect webViewFrame = webView.frame;
	webViewFrame.size.height -= keyboardHeight;
	
	void (^animationBlock)(void) = ^{
		
		webView.frame = webViewFrame;
	};
	
	UIViewAnimationOptions options = 0;
	
	[UIView animateWithDuration:animationDuration
	                      delay:0.0
	                    options:options
	                 animations:animationBlock
	                 completion:NULL];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	float keyboardHeight = 0.0F;
	double animationDuration = 0.0;
	
	[self getKeyboardHeight:&keyboardHeight animationDuration:&animationDuration from:notification];
	
	CGRect webViewFrame = webView.frame;
	webViewFrame.size.height += keyboardHeight;
	
	void (^animationBlock)(void) = ^{
		
		webView.frame = webViewFrame;
	};
	
	UIViewAnimationOptions options = 0;
	
	[UIView animateWithDuration:animationDuration
	                      delay:0.0
	                    options:options
	                 animations:animationBlock
	                 completion:NULL];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	DDLogError(@"webView:didFailLoadWithError: %@", error);
}

- (void)webViewDidFinishLoad:(UIWebView *)sender
{
	NSString *scrollToBottom = @"window.scrollTo(document.body.scrollWidth, document.body.scrollHeight);";
	
    [sender stringByEvaluatingJavaScriptFromString:scrollToBottom];
}

- (void)logError:(NSString *)msg
{
	NSString *prefix = @"<font color=\"#B40404\">";
	NSString *suffix = @"</font><br/>";
	
	[log appendFormat:@"%@%@%@\n", prefix, msg, suffix];
	
	NSString *html = [NSString stringWithFormat:@"<html><body>\n%@\n</body></html>", log];
	[webView loadHTMLString:html baseURL:nil];
}

- (void)logInfo:(NSString *)msg
{
	NSString *prefix = @"<font color=\"#6A0888\">";
	NSString *suffix = @"</font><br/>";
	
	[log appendFormat:@"%@%@%@\n", prefix, msg, suffix];
	
	NSString *html = [NSString stringWithFormat:@"<html><body>\n%@\n</body></html>", log];
	[webView loadHTMLString:html baseURL:nil];
}

- (void)logMessage:(NSString *)msg
{
	NSString *prefix = @"<font color=\"#000000\">";
	NSString *suffix = @"</font><br/>";
	
	[log appendFormat:@"%@%@%@\n", prefix, msg, suffix];
	
	NSString *html = [NSString stringWithFormat:@"<html><body>%@</body></html>", log];
	[webView loadHTMLString:html baseURL:nil];
}

- (IBAction)DisconnectButton:(id)sender {
    
    NSString *host = addrField.text;
    if ([host length] == 0)
    {
        [self logError:@"Address required"];
        return;
    }
    
    int port = [portField.text intValue];
    if (port <= 0 || port > 65535)
    {
        [self logError:@"Valid port required"];
        return;
    }
    NSString *disconnectMessage =@"<Student><Message>Disconnect</Message></Student>";
    
    if ([disconnectMessage length] == 0)
    {
        [self logError:@"Message required"];
        return;
    }
    NSData *data = [disconnectMessage dataUsingEncoding:NSUTF8StringEncoding];
    [udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:tag];
    
    [self logMessage:FORMAT(@"SENT (%i): %@", (int)tag, disconnectMessage)];

    
    
}

- (IBAction)send:(id)sender
{
	NSString *host = addrField.text;
	if ([host length] == 0)
	{
		[self logError:@"Address required"];
		return;
	}
	
	int port = [portField.text intValue];
	if (port <= 0 || port > 65535)
	{
		[self logError:@"Valid port required"];
		return;
	}
	
	//NSString *msg = messageField.text;
    NSString *xmlMessage = [NSString stringWithFormat:@"<Student><Message>%@</Message></Student>",messageField.text];

	if ([xmlMessage length] == 0)
	{
		[self logError:@"Message required"];
		return;
	}
	
	NSData *data = [xmlMessage dataUsingEncoding:NSUTF8StringEncoding];
	[udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:tag];
	
	[self logMessage:FORMAT(@"SENT (%i): %@", (int)tag, xmlMessage)];
	
	//tag++;
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
    NSString *xmlMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *msg = [NSString alloc];
    NSRange replaceRange = [xmlMessage rangeOfString:@"<Student><Message>"];
    if (replaceRange.location != NSNotFound){
        msg = [xmlMessage stringByReplacingCharactersInRange:replaceRange withString:@""];
    }
    replaceRange = [msg rangeOfString:@"</Message></Student>"];
    if (replaceRange.location != NSNotFound)
    {
        NSString* result = [msg stringByReplacingCharactersInRange:replaceRange withString:@""];
        msg = result;
        
    }
	if (msg)
	{
		[self logMessage:FORMAT(@"RECV: %@", msg)];
	}
	else
	{
		NSString *host = nil;
        uint16_t port = 0;
		[GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
		
		[self logInfo:FORMAT(@"RECV: Unknown message from: %@:%hu", host, port)];
	}
}

@end
