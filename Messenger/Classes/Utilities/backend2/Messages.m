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

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface Messages()
{
	NSTimer *timer;
	BOOL refreshUserInterface;
	BOOL refreshUserInterface1;
	BOOL refreshUserInterface2;
	BOOL playMessageIncoming;
	FIRDatabaseReference *firebase;
}
@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation Messages

@synthesize chatId;

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (Messages *)shared
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	static dispatch_once_t once;
	static Messages *messages;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_once(&once, ^{ messages = [[Messages alloc] init]; });
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return messages;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)assignChatId:(NSString *)chatId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self shared].chatId = chatId;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)resignChatId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self shared].chatId = nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)init
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[NotificationCenter addObserver:self selector:@selector(initObservers) name:NOTIFICATION_APP_STARTED];
	[NotificationCenter addObserver:self selector:@selector(initObservers) name:NOTIFICATION_USER_LOGGED_IN];
	[NotificationCenter addObserver:self selector:@selector(actionCleanup) name:NOTIFICATION_USER_LOGGED_OUT];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	timer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(refreshUserInterface) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)initObservers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([FUser currentId] != nil)
	{
		if (firebase == nil) [self createObservers];
	}
}

#pragma mark - Backend methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)createObservers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	long long lastUpdatedAt = [DBMessage lastUpdatedAt];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	firebase = [[[FIRDatabase database] referenceWithPath:FMESSAGE_PATH] child:[FUser currentId]];
	FIRDatabaseQuery *query = [[firebase queryOrderedByChild:FMESSAGE_UPDATEDAT] queryStartingAtValue:@(lastUpdatedAt+1)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[query observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot)
	{
		NSDictionary *message = snapshot.value;
		if (message[FMESSAGE_CREATEDAT] != nil)
		{
			dispatch_async(dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL), ^{
				[self updateRealm:message];
				[self updateChat:message];
				[self playMessageIncoming:message];
				[self refreshUserInterface1:message];
			});
		}
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[query observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot)
	{
		NSDictionary *message = snapshot.value;
		if (message[FMESSAGE_CREATEDAT] != nil)
		{
			dispatch_async(dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL), ^{
				[self updateRealm:message];
				[self updateChat:message];
				[self refreshUserInterface2:message];
			});
		}
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateRealm:(NSDictionary *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:message];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (message[FMESSAGE_MEMBERS] != nil)
		temp[FMESSAGE_MEMBERS] = [message[FMESSAGE_MEMBERS] componentsJoinedByString:@","];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	temp[FMESSAGE_TEXT] = [Cryptor decryptText:message[FMESSAGE_TEXT] chatId:message[FMESSAGE_CHATID]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	RLMRealm *realm = [RLMRealm defaultRealm];
	[realm beginWriteTransaction];
	[DBMessage createOrUpdateInRealm:realm withValue:temp];
	[realm commitWriteTransaction];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateChat:(NSDictionary *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[Chat updateChat:message[FMESSAGE_CHATID] refreshUserInterface:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	refreshUserInterface = YES;
}

#pragma mark - Cleanup methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCleanup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[firebase removeAllObservers]; firebase = nil;
}

#pragma mark - Notification methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshUserInterface1:(NSDictionary *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([message[FMESSAGE_CHATID] isEqualToString:chatId])
	{
		refreshUserInterface1 = YES;
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshUserInterface2:(NSDictionary *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([message[FMESSAGE_CHATID] isEqualToString:chatId])
	{
		refreshUserInterface2 = YES;
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)playMessageIncoming:(NSDictionary *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([message[FMESSAGE_CHATID] isEqualToString:chatId])
	{
		if ([message[FMESSAGE_ISDELETED] boolValue] == NO)
		{
			if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_STATUS] == NO)
			{
				if ([message[FMESSAGE_SENDERID] isEqualToString:[FUser currentId]] == NO)
					playMessageIncoming = YES;
			}
		}
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshUserInterface
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (refreshUserInterface)
	{
		[NotificationCenter post:NOTIFICATION_REFRESH_CHATS];
		refreshUserInterface = NO;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (refreshUserInterface1)
	{
		[NotificationCenter post:NOTIFICATION_REFRESH_MESSAGES1];
		refreshUserInterface1 = NO;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (refreshUserInterface2)
	{
		[NotificationCenter post:NOTIFICATION_REFRESH_MESSAGES2];
		refreshUserInterface2 = NO;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (playMessageIncoming)
	{
		[Audio playMessageIncoming];
		playMessageIncoming = NO;
	}
}

@end
