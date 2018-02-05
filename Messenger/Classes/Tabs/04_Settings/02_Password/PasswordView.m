//
// Copyright (c) 2018 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PasswordView.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface PasswordView()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UITableViewCell *cellPassword0;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellPassword1;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellPassword2;

@property (strong, nonatomic) IBOutlet UITextField *fieldPassword0;
@property (strong, nonatomic) IBOutlet UITextField *fieldPassword1;
@property (strong, nonatomic) IBOutlet UITextField *fieldPassword2;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation PasswordView

@synthesize cellPassword0, cellPassword1, cellPassword2;
@synthesize fieldPassword0, fieldPassword1, fieldPassword2;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.title = @"Change Password";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
																						  action:@selector(actionCancel)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self
																						   action:@selector(actionDone)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
	[self.tableView addGestureRecognizer:gestureRecognizer];
	gestureRecognizer.cancelsTouchesInView = NO;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidAppear:animated];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[fieldPassword0 becomeFirstResponder];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewWillDisappear:animated];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self dismissKeyboard];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)dismissKeyboard
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.view endEditing:YES];
}

#pragma mark - Backend actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)checkPassword
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[ProgressHUD show:nil Interaction:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRUser *firuser = [FIRAuth auth].currentUser;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRAuthCredential *credential = [FIREmailAuthProvider credentialWithEmail:firuser.email password:fieldPassword0.text];
	[firuser reauthenticateWithCredential:credential completion:^(NSError *error)
	{
		if (error == nil)
		{
			[self updatePassword];
		}
		else [ProgressHUD showError:[error description]];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updatePassword
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRUser *firuser = [FIRAuth auth].currentUser;
	[firuser updatePassword:fieldPassword1.text completion:^(NSError *error)
	{
		if (error == nil)
		{
			[ProgressHUD showSuccess:@"Password changed."];
			[self dismissViewControllerAnimated:YES completion:nil];
		}
		else [ProgressHUD showError:[error description]];
	}];
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCancel
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDone
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([fieldPassword0.text length] == 0)	{ [ProgressHUD showError:@"Current Password must be set."]; return; }
	if ([fieldPassword1.text length] == 0)	{ [ProgressHUD showError:@"New Password must be set."]; return; }
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([fieldPassword1.text isEqualToString:fieldPassword2.text] == NO) { [ProgressHUD showError:@"New Passwords must be the same."]; return; }
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self checkPassword];
}

#pragma mark - Table view data source

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return 2;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (section == 0) return 1;
	if (section == 1) return 2;
	return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ((indexPath.section == 0) && (indexPath.row == 0)) return cellPassword0;
	if ((indexPath.section == 1) && (indexPath.row == 0)) return cellPassword1;
	if ((indexPath.section == 1) && (indexPath.row == 1)) return cellPassword2;
	return nil;
}

#pragma mark - Table view delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextField delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)textFieldShouldReturn:(UITextField *)textField
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (textField == fieldPassword0)	[fieldPassword1 becomeFirstResponder];
	if (textField == fieldPassword1)	[fieldPassword2 becomeFirstResponder];
	if (textField == fieldPassword2)	[self actionDone];
	return YES;
}

@end
