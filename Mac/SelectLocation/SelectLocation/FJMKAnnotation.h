//
//  FJMKAnnotation.h
//  SelectLocation
//
//  Created by 熊伟 on 2019/9/7.
//  Copyright © 2019 熊伟. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FJMKAnnotation : NSObject <MKAnnotation>
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic,copy) NSString * title;
@property (nonatomic,copy) NSString * subtitle;
//街道属性信息
@property (nonatomic , copy) NSString * streetAddress ;
// 城市信息属性
@property (nonatomic ,copy) NSString * city ;
// 州，省 市 信息
@property(nonatomic ,copy ) NSString * state ;
//邮编
@property (nonatomic ,copy) NSString * zip  ;

@end

NS_ASSUME_NONNULL_END
