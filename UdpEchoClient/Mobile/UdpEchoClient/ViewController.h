#import <UIKit/UIKit.h>
#import "GCDAsyncUdpSocket.h"

@interface ViewController : UIViewController <GCDAsyncUdpSocketDelegate>
{
	IBOutlet UITextField *addrField;
	IBOutlet UITextField *portField;
	IBOutlet UITextField *messageField;
	IBOutlet UIWebView *webView;
}
- (IBAction)DisconnectButton:(id)sender;

- (IBAction)send:(id)sender;

@end
