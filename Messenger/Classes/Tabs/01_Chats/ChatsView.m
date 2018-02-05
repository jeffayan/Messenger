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

#import "ChatsView.h"
#import "ChatsCell.h"
#import "ChatView.h"
#import "DialogflowView.h"
#import "SelectUserView.h"
#import "NavigationController.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface ChatsView()
{
	NSTimer *timer;
	RLMResults *dbchats;
}

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation ChatsView

@synthesize searchBar;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tabBarItem setImage:[UIImage imageNamed:@"tab_chats"]];
	self.tabBarItem.title = @"Chats";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[NotificationCenter addObserver:self selector:@selector(actionCleanup) name:NOTIFICATION_USER_LOGGED_OUT];
	[NotificationCenter addObserver:self selector:@selector(refreshTableView) name:NOTIFICATION_USER_LOGGED_IN];
	[NotificationCenter addObserver:self selector:@selector(refreshTabCounter) name:NOTIFICATION_USER_LOGGED_IN];
	[NotificationCenter addObserver:self selector:@selector(refreshTableView) name:NOTIFICATION_REFRESH_CHATS];
	[NotificationCenter addObserver:self selector:@selector(refreshTabCounter) name:NOTIFICATION_REFRESH_CHATS];
	[NotificationCenter addObserver:self selector:@selector(refreshTableView) name:NOTIFICATION_REFRESH_STATUSES];
	[NotificationCenter addObserver:self selector:@selector(refreshTabCounter) name:NOTIFICATION_REFRESH_STATUSES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.title = @"Chats";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"chats_dialogflow"]
																	 style:UIBarButtonItemStylePlain target:self action:@selector(actionDialogflow)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self
																						   action:@selector(actionCompose)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	timer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(refreshTableView) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView registerNib:[UINib nibWithNibName:@"ChatsCell" bundle:nil] forCellReuseIdentifier:@"ChatsCell"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.tableView.tableFooterView = [[UIView alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadChats];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidAppear:animated];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([FUser currentId] != nil)
	{
		if ([FUser isOnboardOk])
		{

		}
		else OnboardUser(self);
	}
	else LoginUser(self);
}

#pragma mark - Realm methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadChats
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSPredicate *predicate;
	NSString *text = searchBar.text;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([text length] != 0)
		predicate = [NSPredicate predicateWithFormat:@"isArchived == NO AND isDeleted == NO AND description CONTAINS[c] %@", text];
	else predicate = [NSPredicate predicateWithFormat:@"isArchived == NO AND isDeleted == NO"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dbchats = [[DBChat objectsWithPredicate:predicate] sortedResultsUsingKeyPath:@"lastMessageDate" ascending:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self refreshTableView];
	[self refreshTabCounter];
}

#pragma mark - Refresh methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshTableView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.tableView reloadData];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshTabCounter
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSInteger total = 0;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBChat *dbchat in dbchats)
	{
		long long lastRead = [Status lastRead:dbchat.chatId];
		if (lastRead < dbchat.lastIncoming) total++;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UITabBarItem *item = self.tabBarController.tabBar.items[0];
	item.badgeValue = (total != 0) ? [NSString stringWithFormat:@"%ld", (long) total] : nil;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[UIApplication sharedApplication].applicationIconBadgeNumber = total;
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDialogflow
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DialogflowView *dialogflowView = [[DialogflowView alloc] init];
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:dialogflowView];
	[self presentViewController:navController animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionNewChat
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([[self.tabBarController tabBar] isHidden]) return;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tabBarController setSelectedIndex:0];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self actionCompose];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionRecentUser:(NSString *)userId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([[self.tabBarController tabBar] isHidden]) return;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tabBarController setSelectedIndex:0];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self actionChat:userId];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionChat:(NSString *)recipientId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	ChatView *chatView = [[ChatView alloc] initWith:recipientId];
	chatView.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:chatView animated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCompose
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	SelectUserView *selectUserView = [[SelectUserView alloc] init];
	selectUserView.delegate = self;
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:selectUserView];
	[self presentViewController:navController animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionMore:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBChat *dbchat = dbchats[index];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	long long mutedUntil = [Status mutedUntil:dbchat.chatId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (mutedUntil < [[NSDate date] timestamp])
		[self actionMoreMute:index];
	else [self actionMoreUnmute:index];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionMoreMute:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[alert addAction:[UIAlertAction actionWithTitle:@"Mute" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { [self actionMute:index]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Archive" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { [self actionArchive:index]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self presentViewController:alert animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionMoreUnmute:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[alert addAction:[UIAlertAction actionWithTitle:@"Unmute" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { [self actionUnmute:index]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Archive" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { [self actionArchive:index]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self presentViewController:alert animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionMute:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AdvertPremium(self);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionMute:(NSInteger)index until:(NSInteger)hours
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionUnmute:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionArchive:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBChat *dbchat = dbchats[index];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[Chat archiveItem:dbchat];
	[self refreshTabCounter];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC);
	dispatch_after(time, dispatch_get_main_queue(), ^{ [self refreshTableView]; });
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDelete:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBChat *dbchat = dbchats[index];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[Chat deleteItem:dbchat];
	[self refreshTabCounter];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC);
	dispatch_after(time, dispatch_get_main_queue(), ^{ [self refreshTableView]; });
}

#pragma mark - SelectUserDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didSelectUser:(DBUser *)dbuser
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self actionChat:dbuser.objectId];
}

#pragma mark - Cleanup methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCleanup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self refreshTableView];
	[self refreshTabCounter];
}

#pragma mark - UIScrollViewDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.view endEditing:YES];
}

#pragma mark - Table view data source

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return 1;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [dbchats count];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	ChatsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatsCell" forIndexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	cell.rightButtons = @[[MGSwipeButton buttonWithTitle:@"Delete" backgroundColor:[UIColor redColor]],
						  [MGSwipeButton buttonWithTitle:@"More" backgroundColor:[UIColor lightGrayColor]]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	cell.delegate = self;
	cell.tag = indexPath.row;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[cell bindData:dbchats[indexPath.row]];
	[cell loadImage:dbchats[indexPath.row] tableView:tableView indexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return cell;
}

#pragma mark - MGSwipeTableCellDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction
		 fromExpansion:(BOOL)fromExpansion
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (index == 0) [self actionDelete:cell.tag];
	if (index == 1) [self actionMore:cell.tag];
	return YES;
}

#pragma mark - Table view delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	DBChat *dbchat = dbchats[indexPath.row];
	[self actionChat:dbchat.recipientId];
}

#pragma mark - UISearchBarDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self loadChats];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar setShowsCancelButton:YES animated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar setShowsCancelButton:NO animated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	searchBar.text = @"";
	[searchBar resignFirstResponder];
	[self loadChats];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar resignFirstResponder];
}

@end
