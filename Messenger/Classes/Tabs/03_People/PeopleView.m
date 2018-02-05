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

#import "PeopleView.h"
#import "PeopleCell.h"
#import "ProfileView.h"
#import "AddFriendsView.h"
#import "NavigationController.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface PeopleView()
{
	NSMutableArray *blockerIds;
	NSMutableArray *friendIds;

	RLMResults *dbusers;
	NSMutableArray *sections;
}

@property (strong, nonatomic) IBOutlet UIView *viewTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelTitle;

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation PeopleView

@synthesize viewTitle, labelTitle, searchBar;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tabBarItem setImage:[UIImage imageNamed:@"tab_people"]];
	self.tabBarItem.title = @"People";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[NotificationCenter addObserver:self selector:@selector(actionCleanup) name:NOTIFICATION_USER_LOGGED_OUT];
	[NotificationCenter addObserver:self selector:@selector(loadBlockers) name:NOTIFICATION_USER_LOGGED_IN];
	[NotificationCenter addObserver:self selector:@selector(loadBlockers) name:NOTIFICATION_REFRESH_BLOCKERS];
	[NotificationCenter addObserver:self selector:@selector(loadFriends) name:NOTIFICATION_REFRESH_FRIENDS];
	[NotificationCenter addObserver:self selector:@selector(refreshTableView) name:NOTIFICATION_REFRESH_USERS];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.titleView = viewTitle;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
	[self.navigationItem setBackBarButtonItem:backButton];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self
																						   action:@selector(actionAddFriends)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView registerNib:[UINib nibWithNibName:@"PeopleCell" bundle:nil] forCellReuseIdentifier:@"PeopleCell"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.tableView.tableFooterView = [[UIView alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	blockerIds = [[NSMutableArray alloc] init];
	friendIds = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([FUser currentId] != nil) [self loadBlockers];
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
- (void)loadBlockers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[blockerIds removeAllObjects];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isDeleted == NO"];
	RLMResults *dbblockers = [DBBlocker objectsWithPredicate:predicate];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBBlocker *dbblocker in dbblockers)
		[blockerIds addObject:dbblocker.blockerId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadFriends];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadFriends
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[friendIds removeAllObjects];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isDeleted == NO"];
	RLMResults *dbfriends = [DBFriend objectsWithPredicate:predicate];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBFriend *dbfriend in dbfriends)
		[friendIds addObject:dbfriend.friendId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadUsers];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadUsers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSPredicate *predicate;
	NSString *text = searchBar.text;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([text length] != 0)
	{
		NSString *format = @"NOT objectId IN %@ AND objectId IN %@ AND fullname CONTAINS[c] %@";
		predicate = [NSPredicate predicateWithFormat:format, blockerIds, friendIds, text];
	}
	else predicate = [NSPredicate predicateWithFormat:@"NOT objectId IN %@ AND objectId IN %@", blockerIds, friendIds];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dbusers = [[DBUser objectsWithPredicate:predicate] sortedResultsUsingKeyPath:FUSER_FULLNAME ascending:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self refreshTableView];
}

#pragma mark - Refresh methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshTableView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self setObjects];
	[self.tableView reloadData];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	labelTitle.text = [NSString stringWithFormat:@"(%ld friends)", (long) [dbusers count]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC);
	dispatch_after(time, dispatch_get_main_queue(), ^{ [self setSpotlightSearch]; });
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)setObjects
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (sections != nil) [sections removeAllObjects];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSInteger sectionTitlesCount = [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];
	sections = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (NSUInteger i=0; i<sectionTitlesCount; i++)
	{
		[sections addObject:[NSMutableArray array]];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBUser *dbuser in dbusers)
	{
		NSInteger section = [[UILocalizedIndexedCollation currentCollation] sectionForObject:dbuser collationStringSelector:@selector(fullname)];
		[sections[section] addObject:dbuser];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)setSpotlightSearch
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionAddFriends
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AddFriendsView *addFriendsView = [[AddFriendsView alloc] init];
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:addFriendsView];
	[self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Cleanup methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCleanup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self refreshTableView];
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
	return [sections count];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [sections[section] count];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([sections[section] count] != 0)
	{
		return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section];
	}
	else return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	PeopleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PeopleCell" forIndexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSArray *dbusers_section = sections[indexPath.section];
	DBUser *dbuser = dbusers_section[indexPath.row];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[cell bindData:dbuser];
	[cell loadImage:dbuser tableView:tableView indexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return cell;
}

#pragma mark - Table view delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSArray *dbusers_section = sections[indexPath.section];
	DBUser *dbuser = dbusers_section[indexPath.row];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	ProfileView *profileView = [[ProfileView alloc] initWith:dbuser.objectId Chat:YES];
	profileView.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:profileView animated:YES];
}

#pragma mark - UISearchBarDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self loadUsers];
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
	[self loadUsers];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar resignFirstResponder];
}

@end
