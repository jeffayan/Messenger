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
 
@implementation Cryptor

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (NSString *)encryptText:(NSString *)text chatId:(NSString *)chatId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSData *dataDecrypted = [text dataUsingEncoding:NSUTF8StringEncoding];
	NSData *dataEncrypted = [self encryptData:dataDecrypted chatId:chatId];
	return [dataEncrypted base64EncodedStringWithOptions:0];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (NSString *)decryptText:(NSString *)text chatId:(NSString *)chatId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSData *dataEncrypted = [[NSData alloc] initWithBase64EncodedString:text options:0];
	NSData *dataDecrypted = [self decryptData:dataEncrypted chatId:chatId];
	return [[NSString alloc] initWithData:dataDecrypted encoding:NSUTF8StringEncoding];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (NSData *)encryptData:(NSData *)data chatId:(NSString *)chatId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSError *error;
	NSString *password = [Password get:chatId];
	return [RNEncryptor encryptData:data withSettings:kRNCryptorAES256Settings password:password error:&error];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (NSData *)decryptData:(NSData *)data chatId:(NSString *)chatId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSError *error;
	NSString *password = [Password get:chatId];
	return [RNDecryptor decryptData:data withPassword:password error:&error];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)encryptFile:(NSString *)path chatId:(NSString *)chatId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSData *dataDecrypted = [NSData dataWithContentsOfFile:path];
	NSData *dataEncrypted = [self encryptData:dataDecrypted chatId:chatId];
	[dataEncrypted writeToFile:path atomically:NO];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)decryptFile:(NSString *)path chatId:(NSString *)chatId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSData *dataEncrypted = [NSData dataWithContentsOfFile:path];
	NSData *dataDecrypted = [self decryptData:dataEncrypted chatId:chatId];
	[dataDecrypted writeToFile:path atomically:NO];
}

@end
