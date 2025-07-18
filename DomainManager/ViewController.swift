//
//  ViewController.swift
//  DomainManager
//
//  Created by BJSTTLP185 on 2025/6/30.
//

import UIKit
import Foundation
import CommonCrypto
import Socket

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        let button = UIButton(frame: CGRect.init(x: 100, y: 100, width: 100, height: 100))
        button.backgroundColor = .red
        button.setTitle("Start", for: .normal)
        button.addTarget(self, action: #selector(checkDomains), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func checkDomains() {
        
        fetchDomainJSON { jsonString in
            if let jsonStr = self.aes128Decrypt(codeStr: jsonString ?? "", key: "k0pn@M5cE&l8g@BT") {
                if let json = self.reassembleJSON(from: jsonStr) {
                    DomainManager.shared.checkFastestDomain(for: .app, from: json, isCallBack: true)
                }
            }
        }
    }

    func reassembleJSON(from jsonString: String) -> String? {
        guard let jsonData = jsonString.data(using: .utf8),
              var domainModel = try? JSONDecoder().decode(DomainModel.self, from: jsonData) else {
            return nil
        }

        var newDataArray: [DomainModel.BizDomain] = []
        var copyWebsocketWSS: [String] = []
        var websocketWSS: [String] = []

        for var item in domainModel.data {
            var updatedRegionDomains: [DomainModel.BizDomain.RegionDomain] = []

            for var regionDomain in item.regionDomains {
                guard regionDomain.region == "nv" else {
                    updatedRegionDomains.append(regionDomain)
                    continue
                }

                if let wssList = regionDomain.wss {
                    if item.bizName == "st" {
                        copyWebsocketWSS.append(contentsOf: wssList)
                        regionDomain.wss = nil
                    } else if item.bizName == "nontrade" {
                        websocketWSS.append(contentsOf: wssList)
                        regionDomain.wss = nil
                    }
                }

                updatedRegionDomains.append(regionDomain)
            }

            // 改名
            switch item.bizName {
            case "st":
                item.bizName = "copy"
            case "nontrade":
                item.bizName = "app"
            case "h5":
                item.bizName = "web"
            case "stWs":
                item.bizName = "copyWebsocket"
            case "nontradeWs":
                item.bizName = "websocket"
            default:
                break
            }

            item.regionDomains = updatedRegionDomains
            newDataArray.append(item)
        }

        domainModel = DomainModel(
            refreshInterval: domainModel.refreshInterval,
            mediaUrls: domainModel.mediaUrls,
            data: newDataArray
        )

        guard let newData = try? JSONEncoder().encode(domainModel),
              let newJsonStr = String(data: newData, encoding: .utf8) else {
            return nil
        }

        return newJsonStr
    }
    
    @objc func fetchDomainJSON(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://json.app-alpha.com/domain/ios.last") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/plain", forHTTPHeaderField: "Accept")
        request.setValue("curl/7.68.0", forHTTPHeaderField: "User-Agent")
        request.setValue("close", forHTTPHeaderField: "Connection")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("请求失败：\(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("无数据返回")
                completion(nil)
                return
            }

            if let result = String(data: data, encoding: .utf8) {
                completion(result)
            } else {
                print("数据解析失败")
                completion(nil)
            }
        }

        task.resume()
    }
    
    func aes128Decrypt(codeStr: String, key keyStr: String) -> String? {
        guard let data = Data(base64Encoded: codeStr, options: .ignoreUnknownCharacters) else {
            return ""
        }

        var keyData = Data(count: kCCKeySizeAES128)
        if let keyBytes = keyStr.data(using: .utf8) {
            keyData.replaceSubrange(0..<min(keyBytes.count, kCCKeySizeAES128), with: keyBytes)
        }

        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)

        var numBytesDecrypted: size_t = 0

        let cryptStatus = keyData.withUnsafeBytes { keyBytes in
            data.withUnsafeBytes { dataBytes in
                buffer.withUnsafeMutableBytes { bufferBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES128),
                        CCOptions(kCCOptionECBMode | kCCOptionPKCS7Padding),
                        keyBytes.baseAddress,
                        kCCKeySizeAES128,
                        nil,
                        dataBytes.baseAddress,
                        data.count,
                        bufferBytes.baseAddress,
                        bufferSize,
                        &numBytesDecrypted
                    )
                }
            }
        }

        if cryptStatus == kCCSuccess {
            buffer.count = numBytesDecrypted
            return String(data: buffer, encoding: .utf8)
        } else {
            return nil
        }
    }
}

