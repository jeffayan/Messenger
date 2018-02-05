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
@interface LinkedIds()
{
	FIRDatabaseReference *firebase;
}
@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation LinkedIds

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (LinkedIds *)shared
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	static dispatch_once_t once;
	static LinkedIds *linkedIds;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_once(&once, ^{ linkedIds = [[LinkedIds alloc] init]; });
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return linkedIds;
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
	return self;
}

#pragma mark - Backend methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)initObservers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([FUser currentId] != nil)
	{
		if (firebase == nil) [self createObservers];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)createObservers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	firebase = [[[FIRDatabase database] referenceWithPath:FLINKEDID_PATH] child:[FUser currentId]];
	[firebase observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		if (snapshot.exists)
		{
			BOOL update = ([UserDefaults objectForKey:LINKEDUSERIDS] == nil);
			//-------------------------------------------------------------------------------------------------------------------------------------
			NSArray *userIds = [snapshot.value allKeys];
			[UserDefaults setObject:userIds forKey:LINKEDUSERIDS];
			//-------------------------------------------------------------------------------------------------------------------------------------
			if (update) [LinkedUser update];
		}
	}];
}

#pragma mark - Cleanup methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCleanup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[firebase removeAllObservers]; firebase = nil;
}

@end
