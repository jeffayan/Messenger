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

#import "SelectUserView.h"
#import "SelectUserCell.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface SelectUserView()
{
	NSMutableArray *blockerIds;
	NSMutableArray *friendIds;

	RLMResults *dbusers;
	NSMutableArray *sections;
}

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation SelectUserView

@synthesize delegate;
@synthesize searchBar;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.title = @"Select User";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
																						  action:@selector(actionCancel)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView registerNib:[UINib nibWithNibName:@"SelectUserCell" bundle:nil] forCellReuseIdentifier:@"SelectUserCell"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.tableView.tableFooterView = [[UIView alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	blockerIds = [[NSMutableArray alloc] init];
	friendIds = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadBlockers];
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

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCancel
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIScrollViewDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self dismissKeyboard];
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
	SelectUserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SelectUserCell" forIndexPath:indexPath];
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
	[self dismissViewControllerAnimated:YES completion:^{
		if (delegate != nil) [delegate didSelectUser:dbuser];
	}];
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
