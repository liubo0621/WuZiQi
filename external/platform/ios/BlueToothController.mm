//
//  BlueToothController.m
//  BlueTooth
//
//  Created by LIUBO on 15/9/24.
//
//

#import "BlueToothController.h"
#import <GameKit/GameKit.h>
#import "BleManager.h"
//#import "SVProgressHUD.h"

static BlueToothController *blueToothController = nil;

@interface BlueToothController ()
//- (void)executeReceivedMessageCallback:(NSString *)message;
@end

@implementation BlueToothController {
    GKPeerPickerController *_pickerController;  //通过GKPeerPickerController开启手机蓝牙开关,不需要切换到Setting界面
    GKSession *_currentSession;                 ////GKSession对象用于表现两个蓝牙设备之间连接的一个会话，你也可以使用它在两个设备之间发送和接收数据

    //    std::vector<ReceivedMessageCallback> _receivedMessageCallbacks;
    //    OnConnectedCallback _onConnectedCallback;
    //    OnDisconnectedCallback _onDisconnectedCallback;
    //    CannelConnectedCallback _cannelConnectedCallback;

    bool _isConnected;
}

#pragma mark - click

+ (instancetype)getInstance {
    //    @synchronized 的作用是创建一个互斥锁，保证此时没有其它线程对self对象进行修改
    @synchronized(self) {
        if (blueToothController == nil) {
            blueToothController = [[self alloc] init];
        }
    }

    return blueToothController;
}

/*
 *利用GKPeerPickerController框架搜索附近的蓝牙设备
 */

// 1.蓝牙连接
- (void)searchBleAndConnect {
    _pickerController = [[GKPeerPickerController alloc] init];
    _pickerController.delegate = self;

    _pickerController.connectionTypesMask = GKPeerPickerConnectionTypeNearby;  // 使用蓝牙
    // pickerController.connectionTypesMask = GKPeerPickerConnectionTypeOnline; //基于互联网的连接

    [_pickerController show];
}

// 2.发送数据
- (void)sendMessage:(NSString *)message {
    if (_currentSession) {
        NSString *msg = message;
        NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
        [_currentSession sendDataToAllPeers:data withDataMode:GKSendDataReliable error:nil];
    }
    //    [self executeReceivedMessageCallback:message];
    BleManager::getInstance()->executeReceivedMessageCallback([message UTF8String]);
}

//断开连接
- (void)closeConnected {
    [_currentSession disconnectFromAllPeers];
    _currentSession = nil;
    _pickerController.delegate = nil;
}

- (bool)isConnected {
    return _isConnected;
}

////注册接受到数据的回调
//- (void)addReceivedMessageCallback:(ReceivedMessageCallback)receiveMessageCallback {
//    _receivedMessageCallbacks.push_back(receiveMessageCallback);
//}
//
////注册连接回调
//- (void)addOnConnectedCallback:(OnConnectedCallback)onConnectedCallback {
//    _onConnectedCallback = onConnectedCallback;
//}
//
////注册断开连接回调
//- (void)addOnDisconnectedCallback:(OnDisconnectedCallback)onDisconnectedCallback {
//    _onDisconnectedCallback = onDisconnectedCallback;
//}
//
////注册取消连接回调
//- (void)addCannelConnectedCallback:(CannelConnectedCallback)cannelConnectedCallback {
//    _cannelConnectedCallback = cannelConnectedCallback;
//}
//
////执行收到消息回调
//- (void)executeReceivedMessageCallback:(NSString *)message {
//    for (ReceivedMessageCallback callback : _receivedMessageCallbacks) {
//        callback([message UTF8String]);
//    }
//}

#pragma mark - GKPeerPickerControllerDelegate
- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type {
    _currentSession = [[GKSession alloc] initWithSessionID:@"sunnada_CoreBlueToothDemo" displayName:nil sessionMode:GKSessionModePeer];
    _currentSession.delegate = self;

    return _currentSession;
}

/* Notifies delegate that the user cancelled the picker.
 * 如果用户取消了蓝牙选择器
 */
- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker {
    //[SVProgressHUD showSuccessWithStatus:@"蓝牙连接取消"];

    picker.delegate = nil;
    _currentSession = nil;
    BleManager::getInstance()->executeCannelConnectedCallback();
}

//连接后
- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session {
    _currentSession = session;
    session.delegate = self;
    [session setDataReceiveHandler:self withContext:nil];

    picker.delegate = nil;
    [picker dismiss];
}

#pragma mark - GKSessionDelegate
//设备断开或连接时
- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
    switch (state) {
        case GKPeerStateConnected:
            //[SVProgressHUD showSuccessWithStatus:@"蓝牙已连接"];
            _isConnected = true;

            BleManager::getInstance()->executeOnConnectedCallback();
            break;

        case GKPeerStateDisconnected:
            //[SVProgressHUD showErrorWithStatus:@"蓝牙已断开"];
            _pickerController.delegate = nil;
            _currentSession = nil;
            _isConnected = false;

            BleManager::getInstance()->executeOnDisconnectedCallback();
            break;

        default:
            break;
    }
}

//方法功能：接受数据
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context {
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@", msg);
    //[SVProgressHUD showSuccessWithStatus:@"数据接收成功"];

    BleManager::getInstance()->executeReceivedMessageCallback([msg UTF8String]);
}

@end
