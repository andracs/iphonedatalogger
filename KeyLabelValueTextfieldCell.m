//
//  KeyLabelValueTextfieldCell.m
//  MeterLogger
//
//  Created by johannes on 5/12/14.
//  Copyright (c) 2014 Johannes Gaardsted Jørgensen <johannesgj@gmail.com> + Kristoffer Ek <stoffer@skulp.net>. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License

#import "KeyLabelValueTextfieldCell.h"

@implementation KeyLabelValueTextfieldCell
@synthesize keyLabel;
@synthesize valueTextfield;

- (void)awakeFromNib
{
    [self.valueTextfield setDelegate:self];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)textfieldEditingDidEnd:(UITextField *)sender {
    NSLog(@"lol%@",sender.text);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSLog(@"textField.text %@", textField.text);
    NSLog(@"string %@", string);
/*
    if ([textField.text isEqualToString:@"Lo"]) {
        textField.text = @"Loppen";
        
    }
*/
    return YES;
}

@end
