//
//  do_CountDownLabel_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_CountDownLabel_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doTextHelper.h"
#import "doDefines.h"

#define kDefaultFireIntervalHighUse  0.01

typedef enum{
    doCountDownLabelTimeTypeInMinute, // [0,60) 秒
    doCountDownLabelTimeTypeInHour, // [60,3600) 秒
    doCountDownLabelTimeTypeOverHour // [3600,86400] 秒
}doCountDownLabelTimeType;

@interface do_CountDownLabel_UIView()

@property (nonatomic, assign) double countDownTimeInterval;
@property (nonatomic, assign) BOOL counting;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSDate *startCountDate;
@property (nonatomic, strong) NSDate *timeToCountOff;
@property (nonatomic, strong) NSDate *date1970;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, assign) doCountDownLabelTimeType countDownTimeType;
@end

@implementation do_CountDownLabel_UIView
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    
    _model = (typeof(_model)) _doUIModule;
    
    self.textColor = [UIColor blackColor];
    int fontSize = [doUIModuleHelper GetDeviceFontSize:17 :_model.XZoom :_model.YZoom];
    self.font = [UIFont fontWithName:@"HelveticaNeue" size:fontSize];

    
    _date1970 = [NSDate dateWithTimeIntervalSince1970:0];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    _dateFormatter.dateFormat = @"HH:mm:ss SS";
    _countDownTimeType = doCountDownLabelTimeTypeOverHour;
}

//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
    _model = nil;
        
    if(_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    _startCountDate = nil;
    _timeToCountOff = nil;
    _date1970 = nil;
    _dateFormatter = nil;
}

//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
    
}
#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
- (void)change_countDown:(NSString *)newValue
{
    _countDownTimeInterval = newValue.doubleValue < 0 ? 0 : newValue.doubleValue / 1000.0;
    if (_countDownTimeInterval < 60) {
        _countDownTimeType = doCountDownLabelTimeTypeInMinute;
    }else if (_countDownTimeInterval >= 60 && _countDownTimeInterval < 3600) {
        _countDownTimeType = doCountDownLabelTimeTypeInHour;
    }else if (_countDownTimeInterval >= 3600) {
        _countDownTimeType = doCountDownLabelTimeTypeOverHour;
    }
    _timeToCountOff = [_date1970 dateByAddingTimeInterval:_countDownTimeInterval];
    [self start];
}

- (void)change_fontColor:(NSString *)newValue
{
    self.textColor = [doUIModuleHelper GetColorFromString:newValue :[UIColor blackColor]];
}
- (void)change_fontSize:(NSString *)newValue
{
    int fontSize = [doUIModuleHelper GetDeviceFontSize:[[doTextHelper Instance] StrToInt:newValue :[[_model GetProperty:@"fontSize"].DefaultValue intValue]] :_model.XZoom :_model.YZoom];
    
    self.font = [UIFont fontWithName:@"HelveticaNeue" size:fontSize];
}

- (void)change_textAlign:(NSString *)newValue
{
    NSTextAlignment alignment = NSTextAlignmentLeft;
    
    if([newValue isEqualToString:@"left"])
        alignment = NSTextAlignmentLeft;
    else if([newValue isEqualToString:@"center"])
        alignment = NSTextAlignmentCenter;
    else if([newValue isEqualToString:@"right"])
        alignment = NSTextAlignmentRight;
    
    self.textAlignment = alignment;
}

#pragma mark - private
- (void)start {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    _timer = [NSTimer timerWithTimeInterval:kDefaultFireIntervalHighUse target:self selector:@selector(updateLabel) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    _startCountDate = [NSDate date];
    _counting = YES;
    [_timer fire];
}

- (void)pause {
    if(_counting){
        [_timer invalidate];
        _timer = nil;
        _counting = NO;
    }
}

- (void)updateLabel {
    NSTimeInterval timeDiff = [[NSDate date] timeIntervalSinceDate:_startCountDate];
    NSDate *timeToShow = [NSDate date];
    
    if (_counting) {
  
        if(timeDiff >= _countDownTimeInterval){
            [self pause];
            timeToShow = [_date1970 dateByAddingTimeInterval:0];
            _startCountDate = nil;
            if (_countDownTimeInterval <= 0.0001)return;
            [_model.EventCenter FireEvent:@"finish" :[[doInvokeResult alloc] init]];
        }else{
            
            timeToShow = [_timeToCountOff dateByAddingTimeInterval:(timeDiff*-1)]; //added 0.999 to make it actually counting the whole first second
        }
        
    }else{
        timeToShow = _timeToCountOff;
    }
    self.text = [self getRightFormatTextWith:[self.dateFormatter stringFromDate:timeToShow]];
}

- (NSString *)getRightFormatTextWith:(NSString*)dateText {
    NSString *timeText = [dateText stringByReplacingOccurrencesOfString:@" " withString:@"."];
    NSRange cutRange = NSMakeRange(0, 0);
    switch (_countDownTimeType) {
        case doCountDownLabelTimeTypeInMinute: {
            // 00:00:40.34 -> 40.34
//            cutRange = NSMakeRange(0, 6);
            cutRange = NSMakeRange(0, 3);
            break;
        }
        case doCountDownLabelTimeTypeInHour: {
            // 00:01:40.34 -> 01:40.34
            cutRange = NSMakeRange(0, 3);
            break;
        }
        case doCountDownLabelTimeTypeOverHour: {
            // 01:00:40.34 -> 01:00:40.34
            cutRange = NSMakeRange(0, 0);
            break;
        }
        default:
            break;
    }
    timeText = [timeText substringFromIndex:cutRange.length];
    return timeText;
}

#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end
