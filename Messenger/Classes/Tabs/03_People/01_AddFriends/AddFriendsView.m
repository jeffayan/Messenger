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

#import "AddFriendsView.h"
#import "AddFriendsCell.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface AddFriendsView()
{
	NSMutableArray *users;
	NSMutableArray *sections;
}

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation AddFriendsView

@synthesize searchBar;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.title = @"Add Friends";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self
																						   action:@selector(actionDone)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView registerNib:[UINib nibWithNibName:@"AddFriendsCell" bundle:nil] forCellReuseIdentifier:@"AddFriendsCell"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.tableView.tableFooterView = [[UIView alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	users = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadUsers];
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

#pragma mark - Backend methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadUsers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRDatabaseReference *firebase = [[FIRDatabase database] referenceWithPath:FUSER_PATH];
	[firebase observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		[users removeAllObjects];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if (snapshot.exists)
		{
			for (NSDictionary *dictionary in [snapshot.value allValues])
			{
				FUser *user = [[FUser alloc] initWithPath:FUSER_PATH dictionary:dictionary];
				[users addObject:user];
			}
		}
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[self setObjects];
	}];
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
	for (FUser *user in users)
	{
		NSInteger section = [[UILocalizedIndexedCollation currentCollation] sectionForObject:user collationStringSelector:@selector(fullname)];
		[sections[section] addObject:user];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self refreshTableView];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)createFriend:(FUser *)user
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *userId = user[FUSER_OBJECTID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([Friend isFriend:userId] == NO)
	{
		[Friend createItem:userId];
		[LinkedId createItem:userId];
		[LinkedUser createItem:user];
		[ProgressHUD showSuccess:@"Friend added."];
	}
	else [ProgressHUD showSuccess:@"Already added."];
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
- (void)actionDone
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
	AddFriendsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddFriendsCell" forIndexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSArray *users_section = sections[indexPath.section];
	FUser *user = users_section[indexPath.row];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[cell bindData:user];
	[cell loadImage:user tableView:tableView indexPath:indexPath];
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
	NSArray *users_section = sections[indexPath.section];
	FUser *user = users_section[indexPath.row];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([user isCurrent] == NO)
		[self createFriend:user];
	else [ProgressHUD showSuccess:@"This is you."];
}

#pragma mark - UISearchBarDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	//[self loadUsers];
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
	//[self loadUsers];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar resignFirstResponder];
}

@end
