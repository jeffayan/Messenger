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

#import "ArchiveView.h"
#import "ArchiveCell.h"
#import "ChatView.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface ArchiveView()
{
	NSTimer *timer;
	RLMResults *dbchats;
}

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation ArchiveView

@synthesize searchBar;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.title = @"Archived Chats";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView registerNib:[UINib nibWithNibName:@"ArchiveCell" bundle:nil] forCellReuseIdentifier:@"ArchiveCell"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.tableView.tableFooterView = [[UIView alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadChats];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewWillAppear:animated];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	timer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(refreshTableView) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self refreshTableView];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewWillDisappear:animated];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[timer invalidate]; timer = nil;
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
		predicate = [NSPredicate predicateWithFormat:@"isArchived == YES AND isDeleted == NO AND description CONTAINS[c] %@", text];
	else predicate = [NSPredicate predicateWithFormat:@"isArchived == YES AND isDeleted == NO"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dbchats = [[DBChat objectsWithPredicate:predicate] sortedResultsUsingKeyPath:@"lastMessageDate" ascending:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self refreshTableView];
}

#pragma mark - Refresh methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshTableView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.tableView reloadData];
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionChat:(NSString *)recipientId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	ChatView *chatView = [[ChatView alloc] initWith:recipientId];
	[self.navigationController pushViewController:chatView animated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionMore:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[alert addAction:[UIAlertAction actionWithTitle:@"Unarchive" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) { [self actionUnarchive:index]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self presentViewController:alert animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionUnarchive:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBChat *dbchat = dbchats[index];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[Chat unarchiveItem:dbchat];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC);
	dispatch_after(time, dispatch_get_main_queue(), ^{ [self refreshTableView]; });
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[NotificationCenter post:NOTIFICATION_REFRESH_CHATS];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDelete:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBChat *dbchat = dbchats[index];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[Chat deleteItem:dbchat];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC);
	dispatch_after(time, dispatch_get_main_queue(), ^{ [self refreshTableView]; });
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
	ArchiveCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ArchiveCell" forIndexPath:indexPath];
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
