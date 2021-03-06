//
// WTKeyboard.m
//
// Copyright (c) 2015 wutongr (http://www.wutongr.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "WTKeyboard.h"
#import "WTKeyboardProtocol.h"
#import "WTKeyboardCharPad.h"
#import "WTKeyboardNumPad.h"
#import "WTKeyboardCardPad.h"
#import "WTKeyboardStockPad.h"
#import "WTKeyboardDecimalPad.h"
#import "WTKeyboardSearchPad.h"
#import "WTKeyboardUtils.h"

//#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
//#warning WTKeyboard support iOS7 and later only
//#endif

@interface WTKeyboard ()

@property (nonatomic, strong) id<WTKeyboardProtocol> keyboard;
@property (nonatomic, strong) UIImageView *keyboardBackground;
@property (nonatomic, strong) NSTimer *touchTime;

@end

@implementation WTKeyboard

#pragma mark -
- (instancetype)init{
    if(self = [super init]){
        self.frame = CGRectMake(0, 0, SCREEN_SIZE.width, KEYBOARD_HEIGHT);
        [self setUp];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        [self setUp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]){
        [self setUp];
    }
    return self;
}

#pragma mark -
- (void)setUp{
    if(!_keyboardtype) [self setKeyboardtype:WTKeyboardTypeNumPad];
    //初始
    [_keyboard initPad];
    //清空
    [self.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperview];
    }];
    //构造
    [self addSubview:self.keyboardBackground];
    [_keyboard.characterKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self addSubview:obj];
    }];
    [_keyboard.functionKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self addSubview:obj];
    }];
}

- (BOOL)enableInputClicksWhenVisible{
    return YES;
}

#pragma mark -
- (void)setKeyboardtype:(WTKeyboardType)keyboardtype{
    if(_keyboardtype != keyboardtype){
        _keyboardtype = keyboardtype;
        UIImage *searchBgImage = [UIImage imageNamed:@"keyboard_search_background.png"];
        UIImage *stockBgImage  = [UIImage imageNamed:@"keyboard_stock_background.png"];
        switch (_keyboardtype) {
            case WTKeyboardTypeCharPad:
                self.keyboardBackground.image = searchBgImage;
                _keyboard = [[WTKeyboardCharPad alloc]init];
                break;
            case WTKeyboardTypeNumPad:
                self.keyboardBackground.image = stockBgImage;
                _keyboard = [[WTKeyboardNumPad alloc]init];
                break;
            case WTKeyboardTypeCardPad:
                self.keyboardBackground.image = stockBgImage;
                _keyboard = [[WTKeyboardCardPad alloc]init];
                break;
            case WTKeyboardTypeStockPad:
                self.keyboardBackground.image = stockBgImage;
                _keyboard = [[WTKeyboardStockPad alloc]init];
                break;
            case WTKeyboardTypeDecimalPad:
                self.keyboardBackground.image = stockBgImage;
                _keyboard = [[WTKeyboardDecimalPad alloc]init];
                break;
            case WTKeyboardTypeSearchPad:
                self.keyboardBackground.image = searchBgImage;
                _keyboard = [[WTKeyboardSearchPad alloc]init];
                break;
        }
        [self setUp];
    }
}

- (void)setTextView:(id<UITextInput>)textView{
    if([textView isKindOfClass:[UITextView class]]){
        [(UITextView *)textView setInputView:self];
    }else if ([textView isKindOfClass:[UITextField class]]){
        [(UITextField *)textView setInputView:self];
    }
    _textView = textView;
}

#pragma mark - lazyInit
- (UIImageView *)keyboardBackground{
    if(!_keyboardBackground){
        _keyboardBackground = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_SIZE.width, KEYBOARD_HEIGHT)];
        _keyboardBackground.image = [UIImage imageNamed:@"keyboard_stock_background.png"];
    }
    return _keyboardBackground;
}

#pragma mark - touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    CGPoint location = [[touches anyObject] locationInView:self];
    
    for (UIButton *b in _keyboard.characterKeys) {
        if(CGRectContainsPoint(b.frame, location) && b.hidden == NO)
        {
            [_keyboard touchBegin:b type:WTKeyboardButtonTypeCharacterKey];
            [[UIDevice currentDevice] playInputClick];
            break;
        }
    }
    
    for(UIButton *b in _keyboard.functionKeys){
        if(CGRectContainsPoint(b.frame, location) && b.hidden == NO)
        {
            [_keyboard touchBegin:b type:WTKeyboardButtonTypeFunctionKey];
            [[UIDevice currentDevice] playInputClick];
            
            //退格按钮于其他按钮不同，操作前移
            if([b.titleLabel.text isEqualToString:@"退格"]){
                [self checkBackButton:b touchesBegan:YES];
            }
            break;
        }
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    CGPoint location = [[touches anyObject] locationInView:self];
    
    for (UIButton *b in _keyboard.characterKeys) {
        if(CGRectContainsPoint(b.frame, location) && b.hidden == NO)
        {
            [_keyboard touchMove:b type:WTKeyboardButtonTypeCharacterKey];
            break;
        }
    }
    
    for (UIButton *b in _keyboard.functionKeys) {
        if(CGRectContainsPoint(b.frame, location) && b.hidden == NO)
        {
            [_keyboard touchMove:b type:WTKeyboardButtonTypeFunctionKey];
            break;
        }
    }
}


-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [_keyboard touchEnd];
    
    [self checkBackButton:nil touchesBegan:NO];
    
    CGPoint location = [[touches anyObject] locationInView:self];
    
    for (UIButton *b in _keyboard.characterKeys) {
        if(CGRectContainsPoint(b.frame, location) && b.hidden == NO)
        {
            switch ([_keyboard touchEnd:b]) {
                case WTKeyFunctionInsert:
                {
                    NSString *character = [NSString stringWithString:b.titleLabel.text];

                    if ([self.textView isKindOfClass:[UITextView class]]){
//                        [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self.textView];
                        [self.textView insertText:character];
                    }
                    else if ([self.textView isKindOfClass:[UITextField class]]){
                        UITextField *textField = (UITextField *)self.textView;
                        NSUInteger loc = textField.text.length;
                        
                        if([[textField delegate] respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]){
                            if([[textField delegate] textField:textField shouldChangeCharactersInRange:NSMakeRange(loc, 0) replacementString:character]){
                                [self.textView insertText:character];
                            };
                        }else{
                            [self.textView insertText:character];
                        }
                    }
                }
                    break;
                case WTKeyFunctionDelete:
                case WTKeyFunctionReturn:
                case WTKeyFunctionNormal:
                case WTKeyFunctionUpdate:
                case WTKeyFunctionCancel:
                case WTKeyFunctionClear:
                case WTKeyFunctionCustom:
                    break;
            }
            break;
        }
    }
    
    //功能键
    for(UIButton *b in _keyboard.functionKeys){
        if(CGRectContainsPoint(b.frame, location) && b.hidden == NO)
        {
            switch ([_keyboard touchFunctionEnd:b]) {
                case WTKeyFunctionInsert:
                {
                    if ([self.textView isKindOfClass:[UITextView class]]){
//                        [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self.textView];
                        [self.textView insertText:@" "];
                    }
                    else if ([self.textView isKindOfClass:[UITextField class]]){
                        UITextField *textField = (UITextField *)self.textView;
                        NSUInteger loc = textField.text.length;
                        
                        if([[textField delegate] respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]){
                            if([[textField delegate] textField:textField shouldChangeCharactersInRange:NSMakeRange(loc, 0) replacementString:@" "]){
                                [self.textView insertText:@" "];
                            };
                        }else{
                            [self.textView insertText:@" "];
                        }
                    }
                }
                    break;
                case WTKeyFunctionReturn:
                {
                    if ([self.textView isKindOfClass:[UITextView class]])
                    {
                        [self.textView insertText:@"\n"];
//                        [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self.textView];
                    }
                    else if ([self.textView isKindOfClass:[UITextField class]])
                    {
                        UITextField *textField = (UITextField *)self.textView;
                        if([textField canResignFirstResponder]) [textField resignFirstResponder];
                        
                        if ([[textField delegate] respondsToSelector:@selector(textFieldShouldReturn:)])
                            [[textField delegate] textFieldShouldReturn:(UITextField *)self.textView];
                        
                    }
                }
                    break;
                case WTKeyFunctionUpdate:
                {
                    [self setUp];
                }
                    break;
                case WTKeyFunctionNormal:
                    break;
                case WTKeyFunctionDelete:
                    break;
                case WTKeyFunctionCancel:
                {
                    if ([self.textView isKindOfClass:[UITextField class]])
                    {
                        UITextField *textField = (UITextField *)self.textView;
                        if([textField canResignFirstResponder]) [textField resignFirstResponder];
                    }
                }
                    break;
                case WTKeyFunctionClear:
                    while ([self.textView hasText]) {
                        [self.textView deleteBackward];
                    }
                    
                    if([self.textView isKindOfClass:[UITextField class]]){
                        UITextField *textField = (UITextField *)self.textView;
                        
                        if([[textField delegate] respondsToSelector:@selector(textFieldShouldClear:)])
                            [[textField delegate] textFieldShouldClear:(UITextField *)self.textView];
                    }
                    break;
                case WTKeyFunctionCustom:
                {
                    [[NSNotificationCenter defaultCenter]postNotificationName:WTKeyboardCustomKeyNotification object:b.titleLabel.text];
                }
                    break;
            }
            break;
        }
    }
}

#pragma mark - 退格键处理
- (void)checkBackButton:(UIButton *)button touchesBegan:(BOOL)isBegin{
    if(isBegin){
        //开启计时器
        [self performSelector:@selector(startTouchTime) withObject:nil afterDelay:0.5];
        [self deleteBackward];
    }else{
        //关闭计时器
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startTouchTime) object:nil];
        [self endTouchTime];
    }
}

- (void)startTouchTime{
    self.touchTime = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(deleteBackward) userInfo:nil repeats:YES];
}

- (void)endTouchTime{
    if(self.touchTime && [self.touchTime isValid])
        [self.touchTime invalidate];
}

- (void)deleteBackward{
    if([self.textView hasText]){
        if ([self.textView isKindOfClass:[UITextView class]]){
//                        [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self.textView];
            [self.textView deleteBackward];
        }
        else if ([self.textView isKindOfClass:[UITextField class]]){
            UITextField *textField = (UITextField *)self.textView;
            NSUInteger len = 1;
            NSUInteger loc = textField.text.length - 1;
            
            if([[textField delegate] respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]){
                if([[textField delegate] textField:textField shouldChangeCharactersInRange:NSMakeRange(loc, len) replacementString:@""]){
                    [self.textView deleteBackward];
                };
            }else{
                [self.textView deleteBackward];
            }
        }
    }else{
        [self endTouchTime];
    }
}

@end
