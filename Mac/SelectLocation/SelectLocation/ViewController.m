//
//  ViewController.m
//  SelectLocation
//
//  Created by 熊伟 on 2019/9/7.
//  Copyright © 2019 熊伟. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "FJMKAnnotation.h"
#import "JZLocationConverter.h"

@interface ViewController ()<MKMapViewDelegate,CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (weak) IBOutlet MKMapView *mapView;
@property (weak) IBOutlet NSTextField *addreddTextField;

@property (nonatomic, strong) NSMutableArray * annotationArray;
@property (nonatomic, strong) NSString *gpxFileStr;

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupMapView];
}

-(void)setupMapView {
    MKCoordinateSpan span;
    span.latitudeDelta = 0.077919;
    span.longitudeDelta = 0.044529;
    
    MKCoordinateRegion region ;
    region.center = CLLocationCoordinate2DMake(30.245853, 120.209947);
    region.span = span;
    
    //设置显示区域
    [_mapView setRegion:region];
    //显示定位
    _mapView.showsUserLocation = YES;
    _mapView.showsCompass = YES;
    _mapView.showsScale = YES;
    _mapView.delegate = self;
}

-(CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.distanceFilter = 5;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.delegate = self;
    }
    return _locationManager;
}

-(NSMutableArray *)annotationArray {
    if (_annotationArray) {
        return _annotationArray;
    }
    _annotationArray = [NSMutableArray new];
    return _annotationArray;
}

#pragma mark - action
- (IBAction)searchAction:(id)sender {
    
    NSString * address = self.addreddTextField.stringValue;
    if (!address || address.length <= 0) {
        return;
    }
    [self.mapView removeAnnotations:self.annotationArray];
    [self.annotationArray removeAllObjects];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    __weak typeof(self) weak_self = self;
    [geocoder geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        __strong typeof(weak_self) self = weak_self;
        
        [self.mapView setCenterCoordinate:placemarks.lastObject.location.coordinate animated:YES];
        // 控制区域中心
        CLLocationCoordinate2D center = placemarks.lastObject.location.coordinate;
        // 设置区域跨度
        MKCoordinateSpan span = MKCoordinateSpanMake(1, 1);
        // 创建一个区域
        MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
        // 设置地图显示区域
        [self.mapView setRegion:region animated:YES];
        
        [placemarks enumerateObjectsUsingBlock:^(CLPlacemark * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            FJMKAnnotation *annotation=[[FJMKAnnotation alloc] init];
            CLLocationCoordinate2D coor = obj.location.coordinate;
            
            CGFloat lat = coor.latitude;
            CGFloat lng = coor.longitude;
            
            annotation.coordinate = CLLocationCoordinate2DMake(lat,lng);
            annotation.title = obj.name;
            [self.mapView addAnnotation:annotation];
            [self.annotationArray addObject:annotation];
            
            NSLog(@"%@", obj.name);
        }];
    }];
    
    
}

- (void)modifyGPXAction:(FJMKAnnotation<MKAnnotation>*)annotatoin {
    // 反查得到的是一个gcj的坐标系，和手机上的坐标系不一样，需要转一下
    CLLocationCoordinate2D coor = annotatoin.coordinate;
    coor = [JZLocationConverter gcj02ToWgs84:annotatoin.coordinate];
    
    self.gpxFileStr = [NSString stringWithFormat:@"<?xml version=\"1.0\"?>\n<gpx version=\"1.1\" creator=\"Xcode\">\n<wpt lat=\"%f\" lon=\"%f\">\n<name>China</name>\n</wpt>\n</gpx>", coor.latitude, coor.longitude];
    
    NSURL * gpxFilePath = [[NSUserDefaults standardUserDefaults] URLForKey:@"FJGPXFilePath"];
    if (!gpxFilePath) {
        [self loadGPXFilePath];
    }
    else {
        [self modifyFile:gpxFilePath];
    }
}

-(void)loadGPXFilePath {
    NSAlert *alert = [[NSAlert alloc]init];
    [alert addButtonWithTitle:@"查找文件"];
    [alert addButtonWithTitle:@"不用了"];
    alert.messageText = @"设置GPX文件路径";
    alert.informativeText = @"选择SimLocation项目所依赖的GPX文件。（我知道这很傻，但，先将就吧）";
    [alert setAlertStyle:NSAlertStyleWarning];
    //回调Block
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if(returnCode == NSAlertFirstButtonReturn) {
            
            NSOpenPanel *panel = [NSOpenPanel openPanel];
            panel.allowsMultipleSelection = NO;
            panel.canChooseDirectories = NO;
            panel.resolvesAliases = NO;
            panel.canChooseFiles = YES;
            
            [panel beginWithCompletionHandler:^(NSInteger result){
                if (result == NSModalResponseOK) {
                    NSURL *documentUrl = [[panel URLs] objectAtIndex:0];
                    [self modifyFile:documentUrl];
                }
            }];
        }
    }];
}

-(void)modifyFile:(NSURL*)documentUrl {
    NSError * error;
    [self.gpxFileStr writeToURL:documentUrl atomically:YES encoding:(NSUTF8StringEncoding) error:&error];
    if (error) {
        NSAlert *alert = [[NSAlert alloc]init];
        [alert addButtonWithTitle:@"出错了"];
        alert.messageText = @"修改GPX文件路径出错啦";
        alert.informativeText = @"=。=";
        [alert setAlertStyle:NSAlertStyleWarning];
        //回调Block
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            if(returnCode == NSAlertFirstButtonReturn) {
                self.gpxFileStr = @"";
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FJGPXFilePath"];
            }
        }];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setURL:documentUrl forKey:@"FJGPXFilePath"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - MKMapViewDelegate
/**
 *  当地图获取到用户位置时调用
 *
 *  @param mapView      地图
 *  @param userLocation 大头针数据模型
 */
-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            userLocation.title = @"熊大";
            // 移动地图的中心,显示用户的当前位置
            [self.mapView setCenterCoordinate:userLocation.location.coordinate animated:YES];
            // 控制区域中心
            CLLocationCoordinate2D center = userLocation.location.coordinate;
            // 设置区域跨度
            MKCoordinateSpan span = MKCoordinateSpanMake(0.077919, 0.044529);
            // 创建一个区域
            MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
            // 设置地图显示区域
            [mapView setRegion:region animated:YES];

        });
    });
    
}

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
    NSAlert *alert = [[NSAlert alloc]init];
    [alert addButtonWithTitle:@"确认"];
    [alert addButtonWithTitle:@"再想想"];
    alert.messageText = @"确认根据这个位置修改GPX文件？";
    alert.informativeText = [NSString stringWithFormat:@"%@",view.annotation.title];
    [alert setAlertStyle:NSAlertStyleWarning];
    //回调Block
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if(returnCode == NSAlertFirstButtonReturn) {
            [self modifyGPXAction:view.annotation];
        }
    }];

}

@end
