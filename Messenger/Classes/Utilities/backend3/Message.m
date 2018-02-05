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

@implementation Message

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)deleteItem:(DBMessage *)dbmessage
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([dbmessage.status isEqualToString:TEXT_QUEUED])
	{
		RLMRealm *realm = [RLMRealm defaultRealm];
		[realm beginWriteTransaction];
		dbmessage.isDeleted = YES;
		[realm commitWriteTransaction];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[NotificationCenter post:NOTIFICATION_REFRESH_MESSAGES1];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[Chat updateChat:dbmessage.chatId refreshUserInterface:YES];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([dbmessage.status isEqualToString:TEXT_SENT])
	{
		FObject *object = [FObject objectWithPath:FMESSAGE_PATH Subpath:[FUser currentId]];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		object[FMESSAGE_OBJECTID] = dbmessage.objectId;
		object[FMESSAGE_ISDELETED] = @YES;
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[object updateInBackground];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
}

@end
