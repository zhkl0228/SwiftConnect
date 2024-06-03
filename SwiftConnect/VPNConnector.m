//
//  VPNConnector.m
//  SwiftConnect
//
//  Created by Banny on 2024/6/3.
//

#import "VPNConnector.h"

@implementation VPNConnector

-(void) stopVPNTunnel {
    NSLog(@"stopVPNTunnel");
    [[vpnManager connection] stopVPNTunnel];
}

-(void) startVpn: (BOOL) startImmediately host: (NSString*) host port: (NSString*) port {
    NETunnelProviderProtocol *tunnelProtocol = [NETunnelProviderProtocol new];
    [tunnelProtocol setServerAddress: @"localhost"];
    [tunnelProtocol setProviderBundleIdentifier: @"com.github.zhkl0228.SwiftConnect.extension"];
    [tunnelProtocol setDisconnectOnSleep: NO];
    [tunnelProtocol setExcludeLocalNetworks: YES];
    NSDictionary *conf = @{
        @"host" : host,
        @"port" : port
    };
    [tunnelProtocol setProviderConfiguration: conf];
    
    [self->vpnManager setProtocolConfiguration: tunnelProtocol];
    [self->vpnManager setLocalizedDescription: @"SwiftVpn"];
    [self->vpnManager setEnabled: YES];
    
    [self->vpnManager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        NSLog(@"saveToPreferencesWithCompletionHandler error=%@", error);
        if(error) {
            return;
        }
        
        if(startImmediately) {
            NSError *error = nil;
            BOOL started = [[self->vpnManager connection] startVPNTunnelAndReturnError:&error];
            NSLog(@"saveToPreferencesWithCompletionHandler started=%d, error=%@, NETunnelProviderRoutingMethodSourceApplication=%ld", started, error, (long)NETunnelProviderRoutingMethodSourceApplication);
        } else {
            [self connectHost: host port: port];
        }
    }];
}

-(void) connectHost: (NSString*) host port: (NSString*) port {
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        NSLog(@"connectHost managers=%@, error=%@, manager=%@", managers, error, self->vpnManager);
        if(error) {
            return;
        }
        for(NETunnelProviderManager *manager in managers) {
            if([@"SwiftVpn" isEqualToString: [manager localizedDescription]]) {
                self->vpnManager = manager;
                break;
            }
        }
        if(self->vpnManager) {
            [self startVpn: YES host:host port:port];
        } else {
            self->vpnManager = [NETunnelProviderManager new];
            [self startVpn: NO host:host port:port];
        }
    }];
}

- (void) vpnStatusDidChanged: (NSNotification *) notification {
    NEVPNStatus status = [[vpnManager connection] status];
    NSLog(@"vpnStatusDidChanged notification=%@, status=%ld", notification, (long)status);
}

@end
