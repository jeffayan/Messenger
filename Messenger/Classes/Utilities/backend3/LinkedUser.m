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

@implementation LinkedUser

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)createItem:(FUser *)user
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *userId = user[FUSER_OBJECTID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *currentId = [FUser currentId];
	FUser *currentUser = [FUser currentUser];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRDatabaseReference *firebase1 = [[[FIRDatabase database] referenceWithPath:FLINKEDUSER_PATH] child:currentId];
	[firebase1 updateChildValues:@{userId:user.dictionary}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRDatabaseReference *firebase2 = [[[FIRDatabase database] referenceWithPath:FLINKEDUSER_PATH] child:userId];
	[firebase2 updateChildValues:@{currentId:currentUser.dictionary}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)update
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([UserDefaults objectForKey:LINKEDUSERIDS] != nil)
	{
		NSString *currentId = [FUser currentId];
		FUser *currentUser = [FUser currentUser];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		NSMutableDictionary *multiple = [[NSMutableDictionary alloc] init];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		for (NSString *userId in [UserDefaults objectForKey:LINKEDUSERIDS])
		{
			NSString *path = [NSString stringWithFormat:@"%@/%@", userId, currentId];
			multiple[path] = currentUser.dictionary;
		}
		//-----------------------------------------------------------------------------------------------------------------------------------------
		FIRDatabaseReference *reference = [[FIRDatabase database] referenceWithPath:FLINKEDUSER_PATH];
		[reference updateChildValues:multiple withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref)
		{
			if (error != nil) [ProgressHUD showError:@"Network error."];
		}];
	}
}

@end
