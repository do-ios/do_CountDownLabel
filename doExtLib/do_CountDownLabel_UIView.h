//
//  do_CountDownLabel_View.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "do_CountDownLabel_IView.h"
#import "do_CountDownLabel_UIModel.h"
#import "doIUIModuleView.h"

@interface do_CountDownLabel_UIView : UILabel<do_CountDownLabel_IView, doIUIModuleView>
//可根据具体实现替换UIView
{
	@private
		__weak do_CountDownLabel_UIModel *_model;
}

@end
