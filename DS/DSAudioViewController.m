/*
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * You can obtain a copy of the license at
 * https://solaris.java.net/license.html
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at
 * https://solaris.java.net/license.html.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
 * License for the specific language governing permissions and limitations under
 * the License.
 *
 * Copyright (c) 2015 Jeremy McDermond (NH6Z). All rights reserved.
 *
 */

#import "DSAudioViewController.h"

#import <DStarEngine/DSEDataEngine.h>
#import "DSAudioHandler.h"
#import <CoreAudio/CoreAudio.h>

@interface DSEAudioViewController ()
-(void)refreshDevices;
@end

@implementation DSEAudioViewController

- (void) setSelectedInput:(NSInteger)_selectedInput {
//    [DSEDataEngine sharedInstance].audio.inputDevice = (AudioDeviceID) _selectedInput;
    
    for(NSDictionary *entry in [DSAudioHandler enumerateInputDevices])
        if(((NSNumber *)entry[@"id"]).integerValue == _selectedInput)
            [[NSUserDefaults standardUserDefaults] setObject:entry[@"uid"] forKey:@"inputAudioDevice"];
}

- (NSInteger) selectedInput {
    DSAudioHandler *engineaudio = (DSAudioHandler *)[DSEDataEngine sharedInstance].audio;
    return engineaudio.inputDevice;
}

- (void) setSelectedOutput:(NSInteger)_selectedOutput {
//    [DSEDataEngine sharedInstance].audio.outputDevice = (AudioDeviceID) _selectedOutput;
    
    for(NSDictionary *entry in [DSAudioHandler enumerateOutputDevices])
        if(((NSNumber *)entry[@"id"]).integerValue == _selectedOutput)
            [[NSUserDefaults standardUserDefaults] setObject:entry[@"uid"] forKey:@"outputAudioDevice"];

}

- (NSInteger)selectedOutput {
    DSAudioHandler *engineaudio = (DSAudioHandler *)[DSEDataEngine sharedInstance].audio;
    return engineaudio.outputDevice;
}

- (void)setCourtesyTone:(BOOL)value {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"courtesyTone"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)courtesyTone {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"courtesyTone"];
}

- (void)setVoiceAnnounceOnStatusChange:(BOOL)value {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"voiceAnnounceOnStatusChange"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)voiceAnnounceOnStatusChange {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"voiceAnnounceOnStatusChange"];
}

-(void)refreshDevices {
    [self.inputDeviceMenu removeAllItems];
    for(NSDictionary *entry in [DSAudioHandler enumerateInputDevices]) {
        [self.inputDeviceMenu addItemWithTitle:entry[@"description"]];
        [self.inputDeviceMenu itemWithTitle:entry[@"description"]].tag = ((NSNumber *)entry[@"id"]).integerValue;
    }
    DSAudioHandler *engineaudio = (DSAudioHandler *)[DSEDataEngine sharedInstance].audio;
    [self.inputDeviceMenu selectItemWithTag:engineaudio.inputDevice];
    
    [self.outputDeviceMenu removeAllItems];
    for(NSDictionary *entry in [DSAudioHandler enumerateOutputDevices]) {
        [self.outputDeviceMenu addItemWithTitle:entry[@"description"]];
        [self.outputDeviceMenu itemWithTitle:entry[@"description"]].tag = ((NSNumber *)entry[@"id"]).integerValue;
    }
    NSInteger tag = engineaudio.outputDevice;
    [self.outputDeviceMenu selectItemWithTag: tag];
}

-(void)viewDidLoad {
    [self refreshDevices];
    
    __weak DSEAudioViewController * const weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:DSAudioDeviceChanged
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notification){
                                                      [weakSelf refreshDevices];
                                                  }];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DSAudioDeviceChanged object:nil];
}

@end
