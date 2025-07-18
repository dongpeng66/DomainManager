//
//  DomainSwitchManager.swift
//  DomainManager
//
//  Created by BJSTTLP185 on 2025/7/2.
//

import Foundation

class DomainSwitchManager: NSObject {
    
    // MARK: - 枚举值
    @objc enum DomainSwitchManagerValue: Int {
        case app = 0                           // 非交易
        case copy = 1                         // 跟单
        case trade = 2                       // 交易
        case web = 3                        // h5
        case websocket = 4                 // websocket
        case copyWebsocket = 5            // 跟单 websocket
        case all = 6                     // 所有域名替换
        // 将枚举值映射为对应的字符串（bizName）
        var stringValue: String {
            switch self {
            case .app: return "app"
            case .copy: return "st"
            case .trade: return "trade"
            case .web: return "h5"
            case .websocket: return "nontrade" // websocket 映射到 nontrade 下的 wss
            case .copyWebsocket: return "st" // copyWebsocket 映射到 copy 下的 wss
            case .all: return "all" // copyWebsocket 映射到 copy 下的 wss
            }
        }
    }
    // MARK: - 非交易Count
    var appCount = 0
    // MARK: - 跟单Count
    var copyCount = 0
    // MARK: - 交易Count
    var tradeCount = 0
    // MARK: - h5 Count
    var webCount = 0
    // MARK: - websocket Count
    var websocketCount = 0
    // MARK: - 跟单 websocket Count
    var copyWebsocketCount = 0
    
    
    // MARK: - 累计的最大值
    var maxCount = 3
    
    
    // MARK: - 非交易Count
    var appChecker : DomainLatencyChecker?
    // MARK: - 跟单Count
    var copyChecker : DomainLatencyChecker?
    // MARK: - 交易Count
    var tradeChecker : DomainLatencyChecker?
    // MARK: - h5 Count
    var webChecker : DomainLatencyChecker?
    // MARK: - websocket Count
    var websocketChecker : DomainLatencyChecker?
    // MARK: - 跟单 websocket Count
    var copyWebsocketChecker : DomainLatencyChecker?
    
    // MARK: - 非交易completion
    var appCompletion: ((String?) -> Void)?
    // MARK: - 单completion
    var copyCompletion: ((String?) -> Void)?
    // MARK: - 交易交易completion
    var tradeCompletion: ((String?) -> Void)?
    // MARK: - h5 completion
    var webCompletion: ((String?) -> Void)?
    // MARK: - websocket completion
    var websocketCompletion: ((String?) -> Void)?
    // MARK: - 跟单 websocket completion
    var copyWebsocketCompletion: ((String?) -> Void)?
    
    // MARK: - 非交易completion  累计计数回调
    var appSwitchDomainCompletion: (() -> Void)?
    // MARK: - 单completion  累计计数回调
    var copSwitchDomainyCompletion: (() -> Void)?
    // MARK: - 交易交易completion  累计计数回调
    var tradeSwitchDomainCompletion: (() -> Void)?
    // MARK: - h5 completion  累计计数回调
    var webSwitchDomainCompletion: (() -> Void)?
    // MARK: - websocket completion  累计计数回调
    var websocketSwitchDomainCompletion: (() -> Void)?
    // MARK: - 跟单 websocket completion  累计计数回调
    var copyWebsocketSwitchDomainCompletion: (() -> Void)?
    
    
    // MARK: - 防止多次调用
    private var checkerGueue: [String : String] = [:]
    
    
    @objc public static let shared = DomainSwitchManager()
    override init() {
        appChecker = DomainLatencyChecker()
        copyChecker = DomainLatencyChecker()
        tradeChecker = DomainLatencyChecker()
        webChecker = DomainLatencyChecker()
        websocketChecker = DomainLatencyChecker()
        copyWebsocketChecker = DomainLatencyChecker()
    }
    // MARK: - 增加计数
    @objc func increaseCount(domainValue : DomainSwitchManagerValue) {
        switch domainValue {
        case .app:
            appCount = appCount + 1
            if appCount >= maxCount {
                self.appSwitchDomainCompletion?()
                if let fastestDomain = appChecker?.switchDomain() {
                    self.appCompletion?(fastestDomain)
                }
                
            }
        case .copy:
            copyCount = copyCount + 1
            if copyCount >= maxCount {
                self.copSwitchDomainyCompletion?()
                if let fastestDomain = copyChecker?.switchDomain() {
                    self.copyCompletion?(fastestDomain)
                }
            }
        case .trade:
            tradeCount = tradeCount + 1
            if tradeCount >= maxCount {
                self.tradeSwitchDomainCompletion?()
                if let fastestDomain = tradeChecker?.switchDomain() {
                    self.tradeCompletion?(fastestDomain)
                }
            }
        case .web:
            webCount = webCount + 1
            if webCount >= maxCount {
                self.webSwitchDomainCompletion?()
                if let fastestDomain = webChecker?.switchDomain() {
                    self.webCompletion?(fastestDomain)
                }
            }
        case .websocket:
            websocketCount = websocketCount + 1
            if websocketCount >= maxCount {
                self.websocketSwitchDomainCompletion?()
                if let fastestDomain = websocketChecker?.switchDomain() {
                    self.websocketCompletion?(fastestDomain)
                }
            }
        case .copyWebsocket:
            copyWebsocketCount = copyWebsocketCount + 1
            if copyWebsocketCount >= maxCount {
                self.copyWebsocketSwitchDomainCompletion?()
                if let fastestDomain = copyWebsocketChecker?.switchDomain() {
                    self.copyWebsocketCompletion?(fastestDomain)
                }
            }
        default:
            print("")
        }
    }
    
    
    // MARK: - 重置计数
    
    @objc func clearCount(domainValue : DomainSwitchManagerValue) {
        switch domainValue {
        case .app:
            appCount = 0
        case .copy:
            copyCount = 0
        case .trade:
            tradeCount = 0
        case .web:
            webCount = 0
        case .websocket:
            websocketCount = 0
        case .copyWebsocket:
            copyWebsocketCount = 0
        default:
            print("")
        }
    }
    
    // MARK: - 重置计数
    
    // 检测最优域名
    func findFastestDomain(domainValue : DomainSwitchManagerValue, domains : [String],isCallBack : Bool) {
        
        let domainValueString = domainValue.stringValue
        let checker = checkerGueue[domainValueString]
        if let isChecker = checker,isChecker == "1" {
            // 已经有队列任务再执行中
            return
        }
        checkerGueue[domainValueString] = "1"
        
        
        switch domainValue {
        case .app:
            appChecker?.domains = domains
            appChecker?.findFastestDomain { [weak self] fastestDomain in
                guard let self = self else { return }
                self.checkerGueue[domainValueString] = "0"
                print("self----- \(self)")
                guard let domain = fastestDomain else {
                    print("所有域名检测失败")
                    return
                }
                print("最优节点: \(domain)")
                if isCallBack {
                    self.appCompletion?(fastestDomain)
                }
                
                if let fastest = fastestDomain, !fastest.isEmpty{
                    appCount = 0
                }
                
            }
        case .copy:
            copyChecker?.domains = domains
            copyChecker?.findFastestDomain { [weak self] fastestDomain in
                guard let self = self else { return }
                self.checkerGueue[domainValueString] = "0"
                print("self----- \(self)")
                guard let domain = fastestDomain else {
                    print("所有域名检测失败")
                    return
                }
                print("最优节点: \(domain)")
                if isCallBack {
                    self.copyCompletion?(fastestDomain)
                }
                
                if let fastest = fastestDomain, !fastest.isEmpty{
                    copyCount = 0
                }
                
            }
        case .trade:
            tradeChecker?.domains = domains
            tradeChecker?.findFastestDomain { [weak self] fastestDomain in
                guard let self = self else { return }
                self.checkerGueue[domainValueString] = "0"
                print("self----- \(self)")
                guard let domain = fastestDomain else {
                    print("所有域名检测失败")
                    return
                }
                print("最优节点: \(domain)")
                if isCallBack {
                    self.tradeCompletion?(fastestDomain)
                }
                if let fastest = fastestDomain, !fastest.isEmpty{
                    tradeCount = 0
                }
                
            }
        case .web:
            webChecker?.domains = domains
            webChecker?.findFastestDomain { [weak self] fastestDomain in
                guard let self = self else { return }
                self.checkerGueue[domainValueString] = "0"
                print("self----- \(self)")
                guard let domain = fastestDomain else {
                    print("所有域名检测失败")
                    return
                }
                print("最优节点: \(domain)")
                if isCallBack {
                    self.webCompletion?(fastestDomain)
                }
                if let fastest = fastestDomain, !fastest.isEmpty{
                    webCount = 0
                }
            }
        case .websocket:
            websocketChecker?.domains = domains
            websocketChecker?.findFastestDomain { [weak self] fastestDomain in
                guard let self = self else { return }
                self.checkerGueue[domainValueString] = "0"
                print("self----- \(self)")
                guard let domain = fastestDomain else {
                    print("所有域名检测失败")
                    return
                }
                print("最优节点: \(domain)")
                if isCallBack {
                    self.websocketCompletion?(fastestDomain)
                }
                if let fastest = fastestDomain, !fastest.isEmpty{
                    websocketCount = 0
                }
                
            }
        case .copyWebsocket:
            copyWebsocketChecker?.domains = domains
            copyWebsocketChecker?.findFastestDomain { [weak self] fastestDomain in
                guard let self = self else { return }
                self.checkerGueue[domainValueString] = "0"
                print("self----- \(self)")
                guard let domain = fastestDomain else {
                    print("所有域名检测失败")
                    return
                }
                print("最优节点: \(domain)")
                if isCallBack {
                    self.copyWebsocketCompletion?(fastestDomain)
                }
                if let fastest = fastestDomain, !fastest.isEmpty{
                    copyWebsocketCount = 0
                }
            }
        default:
            print("")
        }
    }
}
