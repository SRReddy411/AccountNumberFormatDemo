//
//  ViewController.m
//  AccountNumberTF
//
//  Created by volive on 7/12/18.
//  Copyright © 2018 volive. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
     [_accountNumTF addTarget:_accountNumTF.delegate
                       action:@selector(reformatAsCardNumber:)
            forControlEvents:UIControlEventEditingChanged];
    NSLog(@"account number %@",_accountNumTF.text);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void)reformatAsCardNumber:(UITextField *)textField
{
    
    NSLog(@"account number of %@",textField.text);
    // In order to make the cursor end up positioned correctly, we need to
    // explicitly reposition it after we inject spaces into the text.
    // targetCursorPosition keeps track of where the cursor needs to end up as
    // we modify the string, and at the end we set the cursor position to it.
    NSUInteger targetCursorPosition =
    [textField offsetFromPosition:textField.beginningOfDocument
                       toPosition:textField.selectedTextRange.start];
    
    NSString *cardNumberWithoutSpaces =
    [self removeNonDigits:textField.text
andPreserveCursorPosition:&targetCursorPosition];
    
    if ([cardNumberWithoutSpaces length] > 16) {
        // If the user is trying to enter more than 19 digits, we prevent
        // their change, leaving the text field in  its previous state.
        // While 16 digits is usual, credit card numbers have a hard
        // maximum of 19 digits defined by ISO standard 7812-1 in section
        // 3.8 and elsewhere. Applying this hard maximum here rather than
        // a maximum of 16 ensures that users with unusual card numbers
        // will still be able to enter their card number even if the
        // resultant formatting is odd.
        [textField setText:_previousTF];
        textField.selectedTextRange = _previousSelection;
        return;
    }
    
    NSString *cardNumberWithSpaces =
    [self insertCreditCardSpaces:cardNumberWithoutSpaces
       andPreserveCursorPosition:&targetCursorPosition];
    
    textField.text = cardNumberWithSpaces;
    UITextPosition *targetPosition =
    [textField positionFromPosition:[textField beginningOfDocument]
                             offset:targetCursorPosition];
    
    [textField setSelectedTextRange:
     [textField textRangeFromPosition:targetPosition
                           toPosition:targetPosition]
     ];
}

-(BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
    // Note textField's current state before performing the change, in case
    // reformatTextField wants to revert it
 
    _previousTF = textField.text;
    _previousSelection = textField.selectedTextRange;
    
    return YES;
}

/*
 Removes non-digits from the string, decrementing `cursorPosition` as
 appropriate so that, for instance, if we pass in `@"1111 1123 1111"`
 and a cursor position of `8`, the cursor position will be changed to
 `7` (keeping it between the '2' and the '3' after the spaces are removed).
 */
- (NSString *)removeNonDigits:(NSString *)string
    andPreserveCursorPosition:(NSUInteger *)cursorPosition
{
    NSUInteger originalCursorPosition = *cursorPosition;
    NSMutableString *digitsOnlyString = [NSMutableString new];
    for (NSUInteger i=0; i<[string length]; i++) {
        unichar characterToAdd = [string characterAtIndex:i];
        if (isdigit(characterToAdd)) {
            NSString *stringToAdd =
            [NSString stringWithCharacters:&characterToAdd
                                    length:1];
            
            [digitsOnlyString appendString:stringToAdd];
        }
        else {
            if (i < originalCursorPosition) {
                (*cursorPosition)--;
            }
        }
    }
    
    return digitsOnlyString;
}

/*
 Detects the card number format from the prefix, then inserts spaces into
 the string to format it as a credit card number, incrementing `cursorPosition`
 as appropriate so that, for instance, if we pass in `@"111111231111"` and a
 cursor position of `7`, the cursor position will be changed to `8` (keeping
 it between the '2' and the '3' after the spaces are added).
 */
- (NSString *)insertCreditCardSpaces:(NSString *)string
           andPreserveCursorPosition:(NSUInteger *)cursorPosition
{
    // Mapping of card prefix to pattern is taken from
    // https://baymard.com/checkout-usability/credit-card-patterns
    
    // UATP cards have 4-5-6 (XXXX-XXXXX-XXXXXX) format
    bool is456 = [string hasPrefix: @"1"];
    
    // These prefixes reliably indicate either a 4-6-5 or 4-6-4 card. We treat all
    // these as 4-6-5-4 to err on the side of always letting the user type more
    // digits.
     bool is465 = [string hasPrefix: @"34"] ||
     [string hasPrefix: @"37"] ||
//
//    // Diners Club
     [string hasPrefix: @"300"] ||
    [string hasPrefix: @"301"] ||
    [string hasPrefix: @"302"] ||
    [string hasPrefix: @"303"] ||
    [string hasPrefix: @"304"] ||
    [string hasPrefix: @"305"] ||
    [string hasPrefix: @"309"] ||
    [string hasPrefix: @"36"] ||
    [string hasPrefix: @"38"] ||
    [string hasPrefix: @"39"];

    // In all other cases, assume 4-4-4-4-3.
    // This won't always be correct; for instance, Maestro has 4-4-5 cards
    // according to https://baymard.com/checkout-usability/credit-card-patterns,
    // but I don't know what prefixes identify particular formats.
    bool is4444 = !(is456 || is465);
    
    NSMutableString *stringWithAddedSpaces = [NSMutableString new];
    NSUInteger cursorPositionInSpacelessString = *cursorPosition;
    for (NSUInteger i=0; i<[string length]; i++) {
        bool needs465Spacing = (is465 && (i == 4 || i == 10 || i == 15));
        bool needs456Spacing = (is456 && (i == 4 || i == 9 || i == 15));
        bool needs4444Spacing = (is4444 && i > 0 && (i % 4) == 0);
        
        if (needs465Spacing || needs456Spacing || needs4444Spacing) {
            [stringWithAddedSpaces appendString:@" "];
            if (i < cursorPositionInSpacelessString) {
                (*cursorPosition)++;
            }
        }
        unichar characterToAdd = [string characterAtIndex:i];
        NSString *stringToAdd =
        [NSString stringWithCharacters:&characterToAdd length:1];
        
        [stringWithAddedSpaces appendString:stringToAdd];
    }
    
    return stringWithAddedSpaces;
}

@end
