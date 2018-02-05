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

#import "MessageSend1.h"

@implementation MessageSend1

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)send:(NSString *)chatId recipientId:(NSString *)recipientId
	  status:(NSString *)status text:(NSString *)text picture:(UIImage *)picture video:(NSURL *)video audio:(NSString *)audio view:(UIView *)view
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"objectId == %@", recipientId];
	DBUser *dbuser = [[DBUser objectsWithPredicate:predicate] firstObject];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *senderPicture		= ([FUser thumbnail] != nil) ? [FUser thumbnail] : @"";
	NSString *recipientPicture	= (dbuser.thumbnail != nil) ? dbuser.thumbnail : @"";
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	FObject *message = [FObject objectWithPath:FMESSAGE_PATH Subpath:chatId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[message objectIdInit];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_CHATID] = chatId;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_MEMBERS] = @[[FUser currentId], recipientId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_SENDERID] = [FUser currentId];
	message[FMESSAGE_SENDERNAME] = [FUser fullname];
	message[FMESSAGE_SENDERINITIALS] = [FUser initials];
	message[FMESSAGE_SENDERPICTURE] = senderPicture;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_RECIPIENTID] = recipientId;
	message[FMESSAGE_RECIPIENTNAME] = dbuser.fullname;
	message[FMESSAGE_RECIPIENTINITIALS] = [dbuser initials];
	message[FMESSAGE_RECIPIENTPICTURE] = recipientPicture;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_PICTURE] = @"";
	message[FMESSAGE_PICTURE_WIDTH] = @0;
	message[FMESSAGE_PICTURE_HEIGHT] = @0;
	message[FMESSAGE_PICTURE_MD5] = @"";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_VIDEO] = @"";
	message[FMESSAGE_VIDEO_DURATION] = @0;
	message[FMESSAGE_VIDEO_MD5] = @"";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_AUDIO] = @"";
	message[FMESSAGE_AUDIO_DURATION] = @0;
	message[FMESSAGE_AUDIO_MD5] = @"";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_LATITUDE] = @0;
	message[FMESSAGE_LONGITUDE] = @0;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_STATUS] = TEXT_SENT;
	message[FMESSAGE_ISDELETED] = @NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_CREATEDAT] = [FIRServerValue timestamp];
	message[FMESSAGE_UPDATEDAT] = [FIRServerValue timestamp];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (status != nil)			[self sendStatusMessage:message status:status];
	else if (text != nil)		[self sendTextMessage:message text:text];
	else if (picture != nil)	[self sendPictureMessage:message picture:picture view:view];
	else if (video != nil)		[self sendVideoMessage:message video:video view:view];
	else if (audio != nil)		[self sendAudioMessage:message audio:audio view:view];
	else						[self sendLoactionMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendStatusMessage:(FObject *)message status:(NSString *)status
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *chatId = message[FMESSAGE_CHATID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_TYPE] = MESSAGE_STATUS;
	message[FMESSAGE_TEXT] = [Cryptor encryptText:status chatId:chatId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self sendMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendTextMessage:(FObject *)message text:(NSString *)text
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *chatId = message[FMESSAGE_CHATID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_TYPE] = [Emoji isEmoji:text] ? MESSAGE_EMOJI : MESSAGE_TEXT;
	message[FMESSAGE_TEXT] = [Cryptor encryptText:text chatId:chatId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self sendMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendPictureMessage:(FObject *)message picture:(UIImage *)picture view:(UIView *)view
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *chatId = message[FMESSAGE_CHATID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_TYPE] = MESSAGE_PICTURE;
	message[FMESSAGE_TEXT] = [Cryptor encryptText:@"[Picture message]" chatId:chatId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSData *dataPicture = UIImageJPEGRepresentation(picture, 0.6);
	NSData *cryptedPicture = [Cryptor encryptData:dataPicture chatId:chatId];
	NSString *md5Picture = [Checksum md5HashOfData:cryptedPicture];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"message_image", @"jpg")];
	FIRStorageUploadTask *task = [reference putData:cryptedPicture metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		[hud hideAnimated:YES];
		if (error == nil)
		{
			NSString *link = metadata.downloadURL.absoluteString;
			NSString *file = [DownloadManager fileImage:link];
			[dataPicture writeToFile:[Dir document:file] atomically:NO];

			message[FMESSAGE_PICTURE] = link;
			message[FMESSAGE_PICTURE_WIDTH] = @((NSInteger) picture.size.width);
			message[FMESSAGE_PICTURE_HEIGHT] = @((NSInteger) picture.size.height);
			message[FMESSAGE_PICTURE_MD5] = md5Picture;

			[self sendMessage:message];
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[task observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot)
	{
		hud.progress = (float) snapshot.progress.completedUnitCount / (float) snapshot.progress.totalUnitCount;
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendVideoMessage:(FObject *)message video:(NSURL *)video view:(UIView *)view
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *chatId = message[FMESSAGE_CHATID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_TYPE] = MESSAGE_VIDEO;
	message[FMESSAGE_TEXT] = [Cryptor encryptText:@"[Video message]" chatId:chatId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSData *dataVideo = [NSData dataWithContentsOfFile:video.path];
	NSData *cryptedVideo = [Cryptor encryptData:dataVideo chatId:chatId];
	NSString *md5Video = [Checksum md5HashOfData:cryptedVideo];
	NSNumber *duration = [Video duration:video.path];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"message_video", @"mp4")];
	FIRStorageUploadTask *task = [reference putData:cryptedVideo metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		[hud hideAnimated:YES];
		if (error == nil)
		{
			NSString *link = metadata.downloadURL.absoluteString;
			NSString *file = [DownloadManager fileVideo:link];
			[dataVideo writeToFile:[Dir document:file] atomically:NO];

			message[FMESSAGE_VIDEO] = link;
			message[FMESSAGE_VIDEO_DURATION] = duration;
			message[FMESSAGE_VIDEO_MD5] = md5Video;

			[self sendMessage:message];
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[task observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot)
	{
		hud.progress = (float) snapshot.progress.completedUnitCount / (float) snapshot.progress.totalUnitCount;
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendAudioMessage:(FObject *)message audio:(NSString *)audio view:(UIView *)view
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *chatId = message[FMESSAGE_CHATID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_TYPE] = MESSAGE_AUDIO;
	message[FMESSAGE_TEXT] = [Cryptor encryptText:@"[Audio message]" chatId:chatId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSData *dataAudio = [NSData dataWithContentsOfFile:audio];
	NSData *cryptedAudio = [Cryptor encryptData:dataAudio chatId:chatId];
	NSString *md5Audio = [Checksum md5HashOfData:cryptedAudio];
	NSNumber *duration = [Audio duration:audio];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"message_audio", @"m4a")];
	FIRStorageUploadTask *task = [reference putData:cryptedAudio metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		[hud hideAnimated:YES];
		if (error == nil)
		{
			NSString *link = metadata.downloadURL.absoluteString;
			NSString *file = [DownloadManager fileAudio:link];
			[dataAudio writeToFile:[Dir document:file] atomically:NO];

			message[FMESSAGE_AUDIO] = link;
			message[FMESSAGE_AUDIO_DURATION] = duration;
			message[FMESSAGE_AUDIO_MD5] = md5Audio;

			[self sendMessage:message];
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[task observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot)
	{
		hud.progress = (float) snapshot.progress.completedUnitCount / (float) snapshot.progress.totalUnitCount;
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendLoactionMessage:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *chatId = message[FMESSAGE_CHATID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_TYPE] = MESSAGE_LOCATION;
	message[FMESSAGE_TEXT] = [Cryptor encryptText:@"[Location message]" chatId:chatId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_LATITUDE] = @([Location latitude]);
	message[FMESSAGE_LONGITUDE] = @([Location longitude]);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self sendMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)sendMessage:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSMutableDictionary *multiple = [[NSMutableDictionary alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (NSString *userId in message[FMESSAGE_MEMBERS])
	{
		NSString *path = [NSString stringWithFormat:@"%@/%@", userId, [message objectId]];
		multiple[path] = message.dictionary;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRDatabaseReference *reference = [[FIRDatabase database] referenceWithPath:FMESSAGE_PATH];
	[reference updateChildValues:multiple withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref)
	{
		if (error == nil)
		{
			[self playMessageOutgoing:message];
			SendPushNotification1(message);
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)playMessageOutgoing:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_STATUS] == NO)
	{
		[Audio playMessageOutgoing];
	}
}

@end
