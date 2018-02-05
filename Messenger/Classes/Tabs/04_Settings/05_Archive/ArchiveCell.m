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

#import "ArchiveCell.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface ArchiveCell()

@property (strong, nonatomic) IBOutlet UIView *viewUnread;
@property (strong, nonatomic) IBOutlet UIImageView *imageUser;
@property (strong, nonatomic) IBOutlet UILabel *labelInitials;

@property (strong, nonatomic) IBOutlet UILabel *labelDescription;
@property (strong, nonatomic) IBOutlet UILabel *labelLastMessage;

@property (strong, nonatomic) IBOutlet UILabel *labelElapsed;
@property (strong, nonatomic) IBOutlet UIImageView *imageMuted;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation ArchiveCell

@synthesize viewUnread, imageUser, labelInitials;
@synthesize labelDescription, labelLastMessage;
@synthesize labelElapsed, imageMuted;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)bindData:(DBChat *)dbchat
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	long long lastRead = [Status lastRead:dbchat.chatId];
	long long mutedUntil = [Status mutedUntil:dbchat.chatId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	viewUnread.hidden = (lastRead >= dbchat.lastIncoming);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	labelDescription.text = dbchat.description;
	labelLastMessage.text = dbchat.lastMessage;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	labelElapsed.text = TimeElapsed(dbchat.lastMessageDate);
	imageMuted.hidden = (mutedUntil < [[NSDate date] timestamp]);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadImage:(DBChat *)dbchat tableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	imageUser.layer.cornerRadius = imageUser.frame.size.width/2;
	imageUser.layer.masksToBounds = YES;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *path = [DownloadManager pathImage:dbchat.picture];
	if (path == nil)
	{
		imageUser.image = [UIImage imageNamed:@"archive_blank"];
		labelInitials.text = dbchat.initials;
		[self downloadImage:dbchat tableView:tableView indexPath:indexPath];
	}
	else
	{
		imageUser.image = [[UIImage alloc] initWithContentsOfFile:path];
		labelInitials.text = nil;
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)downloadImage:(DBChat *)dbchat tableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[DownloadManager image:dbchat.picture completion:^(NSString *path, NSError *error, BOOL network)
	{
		if ((error == nil) && ([tableView.indexPathsForVisibleRows containsObject:indexPath]))
		{
			ArchiveCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			cell.imageUser.image = [[UIImage alloc] initWithContentsOfFile:path];
			cell.labelInitials.text = nil;
		}
		else if (error.code == 102)
		{
			dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
			dispatch_after(time, dispatch_get_main_queue(), ^{
				[self downloadImage:dbchat tableView:tableView indexPath:indexPath];
			});
		}
	}];
}

@end
