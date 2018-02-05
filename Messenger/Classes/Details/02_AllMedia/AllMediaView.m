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

#import "AllMediaView.h"
#import "AllMediaHeader.h"
#import "AllMediaCell.h"
#import "PictureView.h"
#import "VideoView.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface AllMediaView()
{
	NSString *chatId;
	NSMutableArray *selection;
	NSMutableArray *dbmessages_media;

	NSMutableArray *months;
	NSMutableDictionary *dictionary;

	BOOL isSelecting;
	UIBarButtonItem *buttonDone;
	UIBarButtonItem *buttonSelect;
}

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) IBOutlet UIView *viewFooter;
@property (strong, nonatomic) IBOutlet UILabel *labelFooter;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonShare;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonDelete;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation AllMediaView

@synthesize viewFooter, labelFooter, buttonShare, buttonDelete;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWith:(NSString *)chatId_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	chatId = chatId_;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.title = @"All Media";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	buttonDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionCancel)];
	buttonSelect = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStylePlain target:self action:@selector(actionSelect)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.collectionView registerNib:[UINib nibWithNibName:@"AllMediaHeader" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"AllMediaHeader"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.collectionView registerNib:[UINib nibWithNibName:@"AllMediaCell" bundle:nil] forCellWithReuseIdentifier:@"AllMediaCell"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	selection = [[NSMutableArray alloc] init];
	dbmessages_media = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	months = [[NSMutableArray alloc] init];
	dictionary = [[NSMutableDictionary alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self updateViewDetails];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadMedia];
}

#pragma mark - Load methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadMedia
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[months removeAllObjects];
	[dictionary removeAllObjects];
	[dbmessages_media removeAllObjects];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSInteger pictures = 0, videos = 0;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chatId == %@ AND isDeleted == NO", chatId];
	RLMResults *dbmessages = [[DBMessage objectsWithPredicate:predicate] sortedResultsUsingKeyPath:FMESSAGE_CREATEDAT ascending:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBMessage *dbmessage in dbmessages)
	{
		if ([dbmessage.type isEqualToString:MESSAGE_PICTURE])
		{
			if ([DownloadManager pathImage:dbmessage.picture] != nil)
			{
				[dbmessages_media addObject:dbmessage];
				pictures++;
			}
		}
		//-------------------------------------------------------------------------------------------------------------------------------------
		if ([dbmessage.type isEqualToString:MESSAGE_VIDEO])
		{
			if ([DownloadManager pathVideo:dbmessage.video] != nil)
			{
				[dbmessages_media addObject:dbmessage];
				videos++;
			}
		}
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	labelFooter.text = [NSString stringWithFormat:@"Pictures: %ld, Videos: %ld", (long) pictures, (long) videos];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBMessage *dbmessage in dbmessages_media)
	{
		NSDate *created = [NSDate dateWithTimestamp:dbmessage.createdAt];
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy MMM"];
		NSString *month = [formatter stringFromDate:created];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if ([months containsObject:month] == NO) [months addObject:month];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if (dictionary[month] == nil)
			dictionary[month] = [[NSMutableArray alloc] init];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		NSMutableArray *dbmessages_section = dictionary[month];
		[dbmessages_section addObject:dbmessage];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.collectionView reloadData];
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCancel
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	isSelecting = NO;
	[self updateViewDetails];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[selection removeAllObjects];
	[self.collectionView reloadData];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionSelect
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	isSelecting = YES;
	[self updateViewDetails];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (IBAction)actionShare:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AdvertPremium(self);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (IBAction)actionDelete:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive
											handler:^(UIAlertAction *action) { [self actionDelete]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self presentViewController:alert animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDelete
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AdvertPremium(self);
}

#pragma mark - Helper methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateViewDetails
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self.navigationItem.rightBarButtonItem = (isSelecting) ? buttonDone : buttonSelect;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	buttonShare.tintColor = isSelecting ? nil : [UIColor clearColor];
	buttonDelete.tintColor = isSelecting ? nil : [UIColor clearColor];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	buttonShare.enabled = isSelecting;
	buttonDelete.enabled = isSelecting;
}

#pragma mark - UICollectionViewDataSource

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [months count];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *month = months[section];
	NSArray *dbmessages_section = dictionary[month];
	return [dbmessages_section count];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (kind == UICollectionElementKindSectionHeader)
	{
		AllMediaHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"AllMediaHeader" forIndexPath:indexPath];
		header.label.text = months[indexPath.section];
		return header;
	}
	return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AllMediaCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AllMediaCell" forIndexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *month = months[indexPath.section];
	NSArray *dbmessages_section = dictionary[month];
	DBMessage *dbmessage = dbmessages_section[indexPath.item];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	BOOL selected = [selection containsObject:dbmessage.objectId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[cell bindData:dbmessage selected:selected];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return cell;
}

#pragma mark - UICollectionViewDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[collectionView deselectItemAtIndexPath:indexPath animated:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *month = months[indexPath.section];
	NSArray *dbmessages_section = dictionary[month];
	DBMessage *dbmessage = dbmessages_section[indexPath.item];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (isSelecting == NO)
	{
		if ([dbmessage.type isEqualToString:MESSAGE_PICTURE])	[self showPicture:dbmessage];
		if ([dbmessage.type isEqualToString:MESSAGE_VIDEO])		[self showVideo:dbmessage];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (isSelecting == YES)
	{
		if ([selection containsObject:dbmessage.objectId])
			[selection removeObject:dbmessage.objectId];
		else [selection addObject:dbmessage.objectId];
		[self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)showPicture:(DBMessage *)dbmessage
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *path = [DownloadManager pathImage:dbmessage.picture];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (path != nil)
	{
		PictureView *pictureView = [[PictureView alloc] initWith:dbmessage.objectId chatId:chatId];
		pictureView.delegate = self;
		[self presentViewController:pictureView animated:YES completion:nil];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)showVideo:(DBMessage *)dbmessage
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *path = [DownloadManager pathVideo:dbmessage.video];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (path != nil)
	{
		NSURL *url = [NSURL fileURLWithPath:path];
		VideoView *videoView = [[VideoView alloc] initWith:url];
		[self presentViewController:videoView animated:YES completion:nil];
	}
}

#pragma mark - NYTPhotosViewControllerDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)photosViewControllerWillDismiss:(NYTPhotosViewController *)photosViewController
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self loadMedia];
}

@end
