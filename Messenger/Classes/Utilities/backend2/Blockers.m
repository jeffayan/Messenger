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
@interface Blockers()
{
	NSTimer *timer;
	BOOL refreshUserInterface;
	FIRDatabaseReference *firebase;
}
@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation Blockers

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (Blockers *)shared
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	static dispatch_once_t once;
	static Blockers *blockers;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_once(&once, ^{ blockers = [[Blockers alloc] init]; });
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return blockers;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)init
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}


@end
