//
//  ViewController.m
//  SocketTest
//
//  Created by cfg on 16/5/11.
//  Copyright © 2016年 didizhaoren. All rights reserved.
//

#import "ViewController.h"
#import <unistd.h>
#import <arpa/inet.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import "AppDelegate.h"
#define HOST_IP @"192.168.10.243"
#define HOST_Port 5113
@interface ViewController ()
{
    CFSocketRef _socket;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    CFSocketContext CTX = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
//    CFSocketCallBack  call =
   _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketConnectCallBack, TCPServerConnectCallBack, &CTX);

    
    if (_socket !=nil) {
        struct sockaddr_in addr4;

        memset(&addr4, 0, sizeof(addr4));// memset表示将地址addr4结构里面的前sizeof（）个内存地址里面的内容设置成int 0
        addr4.sin_len = sizeof(addr4);
        addr4.sin_family = AF_INET;
        addr4.sin_port = htons(HOST_Port);
        //IP地址
        addr4.sin_addr.s_addr = inet_addr([HOST_IP UTF8String]);
        CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8*)&addr4, sizeof(addr4));
        CFSocketConnectToAddress(_socket, // 连接的socket
                                 address, // CFDataRef类型的包含上面socket的远程地址的对象
                                 -1 // 连接超时时间，如果为负，则不尝试连接，而是把连接放在后台进行，如果_socket消息类型为kCFSocketConnectCallBack，将会在连接成功或失败的时候在后台触发回调函数
                                 );
        CFRunLoopRef cRunRef = CFRunLoopGetCurrent();    // 获取当前线程的循环
        // 创建一个循环，但并没有真正加如到循环中，需要调用CFRunLoopAddSource
        CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault,_socket, 0);
        CFRunLoopAddSource(cRunRef, // 运行循环
                           sourceRef,  // 增加的运行循环源, 它会被retain一次
                           kCFRunLoopCommonModes  // 增加的运行循环源的模式
                           );
        CFRelease(sourceRef);
    }
    
    
}

- (void)readStream {
    char buffer[1024];
    
    while (recv(CFSocketGetNative(_socket), //与本机关联的Socket 如果已经失效返回－1:INVALID_SOCKET
                buffer, sizeof(buffer), 0)) {
        NSLog(@"%@", [NSString stringWithUTF8String:buffer]);
        
        [self sendMessage];
    }
 
}

static void TCPServerConnectCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{

    if (data != NULL) {
        // 当socket为kCFSocketConnectCallBack时，失败时回调失败会返回一个错误代码指针，其他情况返回NULL
        NSLog(@"连接失败");
        return;
    }
    
    NSLog(@"连接成功");
    
    ViewController * delegate = (__bridge ViewController *)info;
    
    // 读取接收的数据
    [delegate performSelectorInBackground:@selector(readStream) withObject:nil];
    

  
    
}

- (void) sendMessage {
   
    NSString *stringToSend = @"hahha";
    const char *data = [stringToSend UTF8String];
    send(CFSocketGetNative(_socket), data, strlen(data) + 1, 0);

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
