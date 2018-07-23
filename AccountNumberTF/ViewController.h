//
//  ViewController.h
//  AccountNumberTF
//
//  Created by volive on 7/12/18.
//  Copyright © 2018 volive. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITextFieldDelegate>

@property NSString *previousTF;
@property (weak, nonatomic) IBOutlet UITextField *accountNumTF;
@property UITextRange *previousSelection;

@end

