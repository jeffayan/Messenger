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

#import <UIKit/UIKit.h>

#import "RCMessage.h"
#import "DBMessage.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface MediaLoader : NSObject
//-------------------------------------------------------------------------------------------------------------------------------------------------

#pragma mark - Picture

+ (void)loadPicture:(RCMessage *)rcmessage dbmessage:(DBMessage *)dbmessage tableView:(UITableView *)tableView;

+ (void)loadPictureManual:(RCMessage *)rcmessage dbmessage:(DBMessage *)dbmessage tableView:(UITableView *)tableView;

#pragma mark - Video

+ (void)loadVideo:(RCMessage *)rcmessage dbmessage:(DBMessage *)dbmessage tableView:(UITableView *)tableView;

+ (void)loadVideoManual:(RCMessage *)rcmessage dbmessage:(DBMessage *)dbmessage tableView:(UITableView *)tableView;

#pragma mark - Audio

+ (void)loadAudio:(RCMessage *)rcmessage dbmessage:(DBMessage *)dbmessage tableView:(UITableView *)tableView;

+ (void)loadAudioManual:(RCMessage *)rcmessage dbmessage:(DBMessage *)dbmessage tableView:(UITableView *)tableView;

@end
