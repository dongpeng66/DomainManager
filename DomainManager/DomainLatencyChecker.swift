//
//  DomainLatencyChecker.swift
//  DomainLatencyChecker
//
//  Created by BJSTTLP185 on 2025/6/30.
//

import Foundation

class DomainLatencyChecker: NSObject {

    // 域名集合
    var domains: [String] = []
    // pinger集合
    private var pingers: [SimplePing] = []
    // ping结果的字典，string(hostName) ：TimeInterval (ms)
    private var results: [String: TimeInterval] = [:]
    // 回调
    private var completion: ((String?) -> Void)?
    // ping开始的字典，string(hostName) ：Date (开始的date)
    private var startTimes: [String: Date] = [:]
    // 当前域名集合中选中的索引
    private var currentIndex = 0
    // 是否已经回调了
    private var isCallBack = false
    
    // 检测最优域名
    func findFastestDomain(completion: @escaping (String?) -> Void) {
        self.completion = completion
        isCallBack = false
        results.removeAll()
        
        domains.forEach { domain in
            let pinger = SimplePing(hostName: domain)
            pinger.delegate = self
            pingers.append(pinger)
            pinger.start()
        }
        
        // 设置超时检测
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self else { return }
            if !self.isCallBack {
                
                pingers.forEach { pinger in
                    if let index = self.results.keys.firstIndex(of: pinger.hostName) {
                        print("索引位置: \(index)---hostName\(pinger.hostName)")
                        
                    } else {
                        print("未找到对象")
                        self.results[pinger.hostName] = TimeInterval.infinity
                    }
                }
                print("self.results.count--\(self.results.count)")
                print("self.domains.count--\(self.domains.count)")
                if self.results.count == self.domains.count {
                    self.finishWithResult()
                }
            }
        }
    }
    
    private func finishWithResult() {
        isCallBack = true
        pingers.forEach { $0.stop() }
        pingers.removeAll()
        
        if !results.isEmpty {
            let sortList = results.sorted { $0.value < $1.value }
            
            var domainList: [String] = []
            
            let fastest = results.first?.key
            sortList.forEach { vv in
                print("域名---\(vv.key)---响应时间----\(vv.value)")
                domainList.append(vv.key)
            }
            domains = domainList
            
            currentIndex = 0

            completion?(fastest)
        } else {
            
            currentIndex = 0

            completion?("")
        }
        
    }
    // 请求失败时切换域名
    func switchDomain() -> String {
        currentIndex = (currentIndex + 1) % domains.count
        if currentIndex < domains.count, !domains.isEmpty {
            return domains[currentIndex]
        }
        print("切换域名失败没有可用的域名")
        return ""
    }
}

extension DomainLatencyChecker: SimplePingDelegate {
    func simplePing(_ pinger: SimplePing, didStartWithAddress address: Data) {
        startTimes[pinger.hostName] = Date()
        pinger.send(with: nil)
    }
    
    func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
        // 记录发送时间
    }
    
    func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
        let latency = Date().timeIntervalSince(startTimes[pinger.hostName] ?? Date()) * 1000
        results[pinger.hostName] = latency
        if results.count == domains.count {
            finishWithResult()
        }
        
    }
    
    func simplePing(_ pinger: SimplePing, didFailWithError error: Error) {
        results[pinger.hostName] = TimeInterval.infinity
        if results.count == domains.count {
            finishWithResult()
        }
    }
}
