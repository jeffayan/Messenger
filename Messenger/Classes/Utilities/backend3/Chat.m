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

#import "utilities.h"

@implementation Chat

#pragma mark - Update methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)updateChat:(NSString *)chatId refreshUserInterface:(BOOL)refreshUserInterface
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chatId == %@ AND isDeleted == NO", chatId];
	DBMessage *dbmessage = [[[DBMessage objectsWithPredicate:predicate] sortedResultsUsingKeyPath:FMESSAGE_CREATEDAT ascending:YES] lastObject];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (dbmessage != nil)
	{
		[self updateItem:dbmessage];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (dbmessage == nil)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chatId == %@", chatId];
		DBChat *dbchat = [[DBChat objectsWithPredicate:predicate] firstObject];
		[self deleteItem:dbchat];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (refreshUserInterface) [NotificationCenter post:NOTIFICATION_REFRESH_CHATS];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)updateItem:(DBMessage *)dbmessage
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RLMRealm *realm = [RLMRealm defaultRealm];
	[realm beginWriteTransaction];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	DBChat *dbchat = [self fetchOrCreateItem:dbmessage.chatId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dbchat.recipientId = @"";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	BOOL incoming = ([dbmessage.senderId isEqualToString:[FUser currentId]] == NO);
	BOOL outgoing = ([dbmessage.senderId isEqualToString:[FUser currentId]] == YES);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (incoming)
	{
		dbchat.recipientId = dbmessage.senderId;
		dbchat.initials = dbmessage.senderInitials;
		dbchat.picture = dbmessage.senderPicture;
		dbchat.description = dbmessage.senderName;
	}
	if (outgoing)
	{
		dbchat.recipientId = dbmessage.recipientId;
		dbchat.initials = dbmessage.recipientInitials;
		dbchat.picture = dbmessage.recipientPicture;
		dbchat.description = dbmessage.recipientName;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dbchat.lastMessage = dbmessage.text;
	dbchat.lastMessageDate = dbmessage.createdAt;
	if (incoming) dbchat.lastIncoming = dbmessage.createdAt;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dbchat.isArchived = NO;
	dbchat.isDeleted = NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dbchat.createdAt = [[NSDate date] timestamp];
	dbchat.updatedAt = [[NSDate date] timestamp];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[realm addOrUpdateObject:dbchat];
	[realm commitWriteTransaction];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (DBChat *)fetchOrCreateItem:(NSString *)chatId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chatId = %@", chatId];
	DBChat *dbchat = [[DBChat objectsWithPredicate:predicate] firstObject];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (dbchat == nil)
	{
		dbchat = [[DBChat alloc] init];
		dbchat.chatId = chatId;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return dbchat;
}

#pragma mark - Delete, Archive methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)deleteItem:(DBChat *)dbchat
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RLMRealm *realm = [RLMRealm defaultRealm];
	[realm beginWriteTransaction];
	dbchat.isDeleted = YES;
	[realm commitWriteTransaction];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)archiveItem:(DBChat *)dbchat
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RLMRealm *realm = [RLMRealm defaultRealm];
	[realm beginWriteTransaction];
	dbchat.isArchived = YES;
	[realm commitWriteTransaction];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)unarchiveItem:(DBChat *)dbchat
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RLMRealm *realm = [RLMRealm defaultRealm];
	[realm beginWriteTransaction];
	dbchat.isArchived = NO;
	[realm commitWriteTransaction];
}

#pragma mark - ChatId methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (NSString *)chatId:(NSString *)recipientId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *currentId = [FUser currentId];
	NSArray *members = @[currentId, recipientId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSArray *sorted = [members sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	return [Checksum md5HashOfString:[sorted componentsJoinedByString:@""]];
}

@end
