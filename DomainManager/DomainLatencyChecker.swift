//
//  DomainLatencyChecker.swift
//  DomainLatencyChecker
//
//  Created by BJSTTLP185 on 2025/6/30.
//

import Foundation

class DomainLatencyChecker: NSObject {

    // 域名集合
    private let domains: [String]
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
    
    init(domains: [String]) {
        self.domains = domains
    }
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
                self.finishWithResult()
            }
        }
    }
    
    private func finishWithResult() {
        isCallBack = true
        pingers.forEach { $0.stop() }
        pingers.removeAll()
        
        let fastest = results.min { $0.value < $1.value }?.key
        results.forEach { vv in
            print("域名---\(vv.key)---响应时间----\(vv.value)")
        }
        
        if let index = domains.firstIndex(of: fastest ?? "") {
            print("索引位置: \(index)")
            currentIndex = index
        } else {
            print("未找到对象")
        }

        completion?(fastest)
    }
    // 请求失败时切换域名
    func switchDomain() -> String {
        currentIndex = (currentIndex + 1) % domains.count
        if currentIndex <= domains.count, !domains.isEmpty {
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
        finishWithResult()
    }
    
    func simplePing(_ pinger: SimplePing, didFailWithError error: Error) {
        results[pinger.hostName] = TimeInterval.infinity
        finishWithResult()
    }
}
