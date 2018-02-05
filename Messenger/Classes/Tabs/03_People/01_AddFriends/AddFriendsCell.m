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

#import "AddFriendsCell.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface AddFriendsCell()

@property (strong, nonatomic) IBOutlet UIImageView *imageUser;
@property (strong, nonatomic) IBOutlet UILabel *labelInitials;

@property (strong, nonatomic) IBOutlet UILabel *labelName;
@property (strong, nonatomic) IBOutlet UILabel *labelStatus;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation AddFriendsCell

@synthesize imageUser, labelInitials;
@synthesize labelName, labelStatus;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)bindData:(FUser *)user
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	labelName.text = user[FUSER_FULLNAME];
	labelStatus.text = user[FUSER_STATUS];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadImage:(FUser *)user tableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	imageUser.layer.cornerRadius = imageUser.frame.size.width/2;
	imageUser.layer.masksToBounds = YES;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *path = [DownloadManager pathImage:user[FUSER_THUMBNAIL]];
	if (path == nil)
	{
		imageUser.image = [UIImage imageNamed:@"addfriends_blank"];
		labelInitials.text = [user initials];
		[self downloadImage:user tableView:tableView indexPath:indexPath];
	}
	else
	{
		imageUser.image = [[UIImage alloc] initWithContentsOfFile:path];
		labelInitials.text = nil;
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)downloadImage:(FUser *)user tableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[DownloadManager image:user[FUSER_THUMBNAIL] completion:^(NSString *path, NSError *error, BOOL network)
	{
		if ((error == nil) && ([tableView.indexPathsForVisibleRows containsObject:indexPath]))
		{
			AddFriendsCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			cell.imageUser.image = [[UIImage alloc] initWithContentsOfFile:path];
			cell.labelInitials.text = nil;
		}
		else if (error.code == 102)
		{
			dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
			dispatch_after(time, dispatch_get_main_queue(), ^{
				[self downloadImage:user tableView:tableView indexPath:indexPath];
			});
		}
	}];
}

@end
