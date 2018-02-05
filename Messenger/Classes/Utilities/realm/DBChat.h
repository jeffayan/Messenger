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

#import <Realm/Realm.h>

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface DBChat : RLMObject
//-------------------------------------------------------------------------------------------------------------------------------------------------

@property NSString *chatId;
@property NSString *recipientId;

@property NSString *initials;
@property NSString *picture;
@property NSString *description;

@property NSString *lastMessage;
@property long long lastMessageDate;
@property long long lastIncoming;

@property BOOL isArchived;
@property BOOL isDeleted;

@property long long createdAt;
@property long long updatedAt;

@end
