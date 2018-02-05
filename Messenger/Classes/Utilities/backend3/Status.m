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

@implementation Status

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)updateLastRead:(NSString *)chatId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	long long mutedUntil = [self mutedUntil:chatId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FObject *object = [FObject objectWithPath:FSTATUS_PATH Subpath:[FUser currentId]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	object[FSTATUS_OBJECTID] = chatId;
	object[FSTATUS_CHATID] = chatId;
	object[FSTATUS_LASTREAD] = [FIRServerValue timestamp];
	object[FSTATUS_MUTEDUNTIL] = @(mutedUntil);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[object saveInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			[object fetchInBackground:^(NSError *error)
			{
				FIRDatabaseReference *firebase = [[[FIRDatabase database] referenceWithPath:FLASTREAD_PATH] child:chatId];
				[firebase updateChildValues:@{[FUser currentId]:object[FSTATUS_LASTREAD]}];
			}];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)updateMutedUntil:(NSString *)chatId mutedUntil:(long long)mutedUntil
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	long long lastRead = [self lastRead:chatId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FObject *object = [FObject objectWithPath:FSTATUS_PATH Subpath:[FUser currentId]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	object[FSTATUS_OBJECTID] = chatId;
	object[FSTATUS_CHATID] = chatId;
	object[FSTATUS_LASTREAD] = @(lastRead);
	object[FSTATUS_MUTEDUNTIL] = @(mutedUntil);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[object saveInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			FIRDatabaseReference *firebase = [[[FIRDatabase database] referenceWithPath:FMUTEDUNTIL_PATH] child:chatId];
			[firebase updateChildValues:@{[FUser currentId]:@(mutedUntil)}];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (long long)lastRead:(NSString *)chatId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chatId == %@", chatId];
	DBStatus *dbstatus = [[DBStatus objectsWithPredicate:predicate] firstObject];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return dbstatus.lastRead;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (long long)mutedUntil:(NSString *)chatId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chatId == %@", chatId];
	DBStatus *dbstatus = [[DBStatus objectsWithPredicate:predicate] firstObject];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return dbstatus.mutedUntil;
}

@end
