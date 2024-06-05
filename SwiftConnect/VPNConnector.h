//
//  VPNConnector.h
//  SwiftConnect
//
//  Created by Banny on 2024/6/3.
//

#ifndef VPNConnector_h
#define VPNConnector_h

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>

@interface VPNConnector : NSObject {
    NETunnelProviderManager *vpnManager;
    NSDictionary *vpnConfiguration;
}

-(NSDictionary *) vpnConfiguration;

-(void) stopVPNTunnel;

-(void) connectHost: (NSString*) host port: (NSString*) port;

@end


#endif /* VPNConnector_h */
