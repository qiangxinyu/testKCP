//
//  ViewController.m
//  testKCP
//
//  Created by 强新宇 on 2016/10/13.
//  Copyright © 2016年 强新宇. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncUdpSocket.h"
#import "ikcp.h"
static int port = 1101122;
static NSString * host = @"192.168.0.25";

@interface ViewController () <GCDAsyncUdpSocketDelegate>
@end

ikcpcb * kcp;
GCDAsyncUdpSocket * udpSocket;


int udp_output(const char * buf, int len, ikcpcb * kcp, void * user)
{
    NSData * data = [NSData dataWithBytes:buf length:len];
    [udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:arc4random()%55];
    
    int a;
    [data getBytes:&a length:sizeof(a)];
    
    printf(" --- udp send --- %d",a);
    
    return 0;
}

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    kcp = ikcp_create(port, NULL);
    kcp->output = udp_output;
    
    // 而考虑到丢包重发，设置最大收发窗口为128
    ikcp_wndsize(kcp, 128, 128);
    
    ikcp_nodelay(kcp, 1, 10, 2, 1);
    kcp->rx_minrto = 10;
    kcp->fastresend = 1;
    
    [NSTimer scheduledTimerWithTimeInterval:0.01 repeats:YES block:^(NSTimer * _Nonnull timer) {
        ikcp_update(kcp, [NSDate date].timeIntervalSince1970);
    }];

    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

- (IBAction)clickSend:(id)sender {
    
    const char str[] = "\x00\x00\x00\x01";
    
    int a = ikcp_send(kcp, str, sizeof(str));
    NSLog(@" -- ikcp_send => %d",a);
}

/**
 * Called when the datagram with the given tag has been sent.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@" --- 发送成功  tag ===> %ld",tag);
}

/**
 * Called if an error occurs while trying to send a datagram.
 * This could be due to a timeout, or something more serious such as the data being too large to fit in a sigle packet.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@" --- 发送失败 -- %@",error);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
