//
//  ViewController.m
//  CLLocation反编码
//
//  Created by use on 16/6/20.
//  Copyright © 2016年 wjp. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager* locationManager;

@property (strong,nonatomic) CLGeocoder *geo;
@property (weak, nonatomic) IBOutlet UITextField *longtitudeTF;
@property (weak, nonatomic) IBOutlet UITextField *latitudeTF;

@property (nonatomic, copy) NSDictionary *locationInfo;

@property (weak, nonatomic) IBOutlet UITextView *resultTextView;

@property (nonatomic, copy) NSMutableString *locationInfoString;

@property (nonatomic, assign) NSInteger count; // 定位次数

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _locationInfoString = [NSMutableString new];
}

// 自定义经纬度定位
- (IBAction)start:(UIButton *)sender {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[_latitudeTF.text doubleValue] longitude:[_longtitudeTF.text doubleValue]];
    _locationInfoString = [@"" mutableCopy];
    [self reversePlaceCode:location];
}

// 系统定位
- (IBAction)jp_location_system_start:(UIButton *)sender {
    sender.selected = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sender.selected = NO;
    });
    _locationInfoString = [@"" mutableCopy];
    _count = 0;
    [self startLocation];
}

- (void)reversePlaceCode:(CLLocation *)locationx
{
    CLLocation *location = locationx;
    
    CLLocationCoordinate2D coordinate = location.coordinate;
    
    __weak typeof(self) weakself = self;
    
    [_locationInfoString appendFormat:@"=======================\n"];
    
    [self.geo reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        for (int i = 0; i < placemarks.count; ++i) {
            CLPlacemark *place = placemarks[i];
            
            weakself.locationInfo = place.addressDictionary;
            
            [_locationInfoString appendFormat:@"*********** place%d ************\n -- 纬度:%f,经度:%f,  \n", i, coordinate.latitude, coordinate.longitude];
            
            for (NSString *key in weakself.locationInfo.allKeys) {
                if ([key isEqualToString:@"FormattedAddressLines"]) {
                    [_locationInfoString appendString:@"-------------------\n"];
                    NSArray *value = weakself.locationInfo[key];
                    for (NSString *str in value) {
                        NSLog(@"%@\n", str);
                        [_locationInfoString appendFormat:@"%@\n", str];
                    }
                    [_locationInfoString appendString:@"-------------------\n"];
                    continue;
                }
                NSLog(@"%@ = %@\n", key, weakself.locationInfo[key]);
                
                [_locationInfoString appendFormat:@"%@ = %@, \n", key, weakself.locationInfo[key]];
            }
        }
        
        _resultTextView.text = _locationInfoString;
    }];
}

- (CLGeocoder *)geo
{
    if (_geo == nil) {
        _geo = [[CLGeocoder alloc] init];
    }
    return _geo;
}

#pragma mark -- 系统定位
- (void)startLocation
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    /** 由于IOS8中定位的授权机制改变 需要进行手动授权
     * 获取授权认证，两个方法：
     * [self.locationManager requestWhenInUseAuthorization];
     * [self.locationManager requestAlwaysAuthorization];
     */
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            NSLog(@"requestWhenInUseAuthorization");
            [self.locationManager requestWhenInUseAuthorization];
        }
    }
    
    //开始定位，不断调用其代理方法
    [self.locationManager startUpdatingLocation];
    NSLog(@"start gps");
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    // 1.停止定位
    if (++_count > 10) {
        [manager stopUpdatingLocation];
    }
    
    // 2.获取用户位置的对象
    CLLocation *location = [locations lastObject];
    
    [self reversePlaceCode:location];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
