//
//  DomainManager.swift
//  DomainManager
//
//  Created by muzi li on 2025/7/3.
//

import UIKit

class DomainManager: NSObject {
    
    static let shared = DomainManager()
    private var domainData: [String: [String]] = [:]
    
    override init() {
        super.init()
        DomainSwitchManager.shared.appCompletion = { [weak self] fastestDomain in
            guard let self = self else { return }
            // 拼接特定的路径
            let finalDomain = self.appendPath(for: .app, fastestDomain: fastestDomain)
        }
        DomainSwitchManager.shared.copyCompletion = { [weak self] fastestDomain in
            guard let self = self else { return }
            // 拼接特定的路径
            let finalDomain = self.appendPath(for: .copy, fastestDomain: fastestDomain)
        }
        DomainSwitchManager.shared.tradeCompletion = { [weak self] fastestDomain in
            guard let self = self else { return }
            // 拼接特定的路径
            let finalDomain = self.appendPath(for: .trade, fastestDomain: fastestDomain)
        }
        DomainSwitchManager.shared.webCompletion = { [weak self] fastestDomain in
            guard let self = self else { return }
            // 拼接特定的路径
            let finalDomain = self.appendPath(for: .web, fastestDomain: fastestDomain)
        }
        DomainSwitchManager.shared.websocketCompletion = { [weak self] fastestDomain in
            guard let self = self else { return }
            // 拼接特定的路径
            let finalDomain = self.appendPath(for: .websocket, fastestDomain: fastestDomain)
        }
        DomainSwitchManager.shared.copyWebsocketCompletion = { [weak self] fastestDomain in
            guard let self = self else { return }
            // 拼接特定的路径
            let finalDomain = self.appendPath(for: .copyWebsocket, fastestDomain: fastestDomain)
        }
        
        
        // 累计计数回调重新请求
        
        DomainSwitchManager.shared.appSwitchDomainCompletion = {
            
        }
        DomainSwitchManager.shared.copSwitchDomainyCompletion = {
            
        }
        DomainSwitchManager.shared.tradeSwitchDomainCompletion = {
            
        }
        DomainSwitchManager.shared.webSwitchDomainCompletion = {
            
        }
        DomainSwitchManager.shared.websocketSwitchDomainCompletion = {
            
        }
        DomainSwitchManager.shared.copyWebsocketSwitchDomainCompletion = {
            
        }
        
        
    }
    
    // 使用枚举值获取最优域名
    func checkFastestDomain(for switchValue: DomainSwitchManager.DomainSwitchManagerValue, from jsonString: String, isCallBack : Bool) {
        
        // 解析并加载数据
        loadDomainData(from: jsonString)
        
        if switchValue == .all {

            for typeValue in 0...5 {
                // 选择对应业务类型的域名
                let bizName = switchValue.stringValue
                
                guard let domains = domainData[bizName] else {
                    print("没有找到 \(bizName) 的域名")
                    
                    return
                }
                
                
                
                // 使用延迟检查器选择最优的域名
                DomainSwitchManager.shared.findFastestDomain(domainValue: DomainSwitchManager.DomainSwitchManagerValue(rawValue: typeValue) ?? DomainSwitchManager.DomainSwitchManagerValue.app, domains: domains, isCallBack: isCallBack)
            }
        } else {
            // 选择对应业务类型的域名
            let bizName = switchValue.stringValue
            
            guard let domains = domainData[bizName] else {
                print("没有找到 \(bizName) 的域名")
                return
            }
            
            
            
            // 使用延迟检查器选择最优的域名
            DomainSwitchManager.shared.findFastestDomain(domainValue: switchValue, domains: domains, isCallBack: isCallBack)
        }

    }
    // MARK: - 增加计数
    @objc func increaseCount(domainValue : DomainSwitchManager.DomainSwitchManagerValue) {
        
        DomainSwitchManager.shared.increaseCount(domainValue: domainValue)
    }
    
    
    // MARK: - 重置计数
    
    @objc func clearCount(domainValue : DomainSwitchManager.DomainSwitchManagerValue) {
        DomainSwitchManager.shared.clearCount(domainValue: domainValue)
    }
    
    func extractPingHost(from urlString: String) -> String {
        if let url = URL(string: urlString), let host = url.host {
            return host
        }

        if urlString.contains(":") {
            return urlString.components(separatedBy: ":").first ?? ""
        }

        return urlString
    }
    
    // 加载数据
    private func loadDomainData(from jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let model = try? JSONDecoder().decode(DomainModel.self, from: data) else {
            print("域名 JSON 解析失败")
            return
        }
        
        // 解析数据
        for biz in model.data {
            var domains: [String] = []
            for region in biz.regionDomains {
                appendDomains(from: region, to: &domains)
            }
            domainData[biz.bizName] = domains
        }
    }
    
    // 抽取协议解析部分
    private func appendDomains(from region: DomainModel.BizDomain.RegionDomain, to domains: inout [String]) {
        region.https?.forEach { domains.append("https://\($0)") }
        region.wss?.forEach { domains.append("wss://\($0)") }
        region.http?.forEach { domains.append("http://\($0)") }
        region.ws?.forEach { domains.append("ws://\($0)") }
    }

    // 根据业务类型拼接域名
    private func appendPath(for switchValue: DomainSwitchManager.DomainSwitchManagerValue, fastestDomain: String?) -> String? {
        guard let fastestDomain = fastestDomain else { return nil }
        
        let pathMap: [DomainSwitchManager.DomainSwitchManagerValue: String] = [
            .app: "/vau",
            .copy: "/stTradeApp",
            .web: "/h5/feature",
            .websocket: "/websocket",
            .copyWebsocket: "/websocket",
            .trade: ""
        ]
        
        let suffix = pathMap[switchValue] ?? ""
        return fastestDomain + suffix
    }
}
