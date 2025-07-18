//
//  DomainDataManager.swift
//  DomainManager
//
//  Created by muzi li on 2025/7/3.
//
// 用于解密和解析域名配置 JSON 数据，输出模块 -> 域名列表的映射结构
import UIKit

struct DomainModel: Codable {
    
    let refreshInterval: Int // 域名文件刷新间隔
    let mediaUrls: [String] // 远端文件链接
    let data: [BizDomain] // 域名信息

    struct BizDomain: Codable {
        var bizName: String // 业务域名称
        var regionDomains: [RegionDomain] // ✅ 改为数组

        struct RegionDomain: Codable {
            var region: String
            var https: [String]?
            var http: [String]?
            var wss: [String]?
            var ws: [String]?
        }
    }
}

class DomainDataManager {
    static let shared = DomainDataManager()
    var domainMap: [String: [String]] = [:] // bizName: [完整域名]
    
    func loadDomainList(from jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let model = try? JSONDecoder().decode(DomainModel.self, from: data) else {
            print("域名 JSON 解析失败")
            return
        }
        
        for biz in model.data {
            var fullDomains: [String] = []
            for region in biz.regionDomains {
                // 处理 https 协议
                if let httpsDomains = region.https {
                    httpsDomains.forEach { fullDomains.append("https://\($0)") }
                }
                // 处理 wss 协议
                if let wssDomains = region.wss {
                    wssDomains.forEach { fullDomains.append("wss://\($0)") }
                }
                // 处理 http 协议
                if let httpDomains = region.http {
                    httpDomains.forEach { fullDomains.append("http://\($0)") }
                }
                // 处理 ws 协议
                if let wsDomains = region.ws {
                    wsDomains.forEach { fullDomains.append("ws://\($0)") }
                }
            }
            domainMap[biz.bizName] = fullDomains
        }
    }
}
