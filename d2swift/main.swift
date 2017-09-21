// Copyright 1017 Daher Alfawares & Ricky Powell
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0

import Foundation


func end() -> String {
    return "\n"
}

func tab(_ level:Int) -> String {
    var o = String()
    for var i in 0..<level {
        o += "    "
        i += 0
    }
    return o
}

func class_name(_ key:String) -> String {
    return key.capitalized + "Type"
}

func var_name(_ key:String) -> String {
    var string = ""
    guard key != key.uppercased() else {
        return key.lowercased().replacingOccurrences(of: " ", with: "")
    }
    for (i, value) in key.characters.enumerated() {
        if i == 0 {
            string += String(value).lowercased()
        }
        else {
            string += String(value)
        }
    }
    
    return string.replacingOccurrences(of: " ", with: "")
}

func declare(_ key:String,_ value:Any,_ i: Int) -> String {
    var o = String()
    
    if let _ = value as? String {
        o += tab(i) + "let \(var_name(key)) : String"
    }
    
    
    if let value = value as? [Any] {
        if value.isEmpty {
            o += tab(i) + "let \(var_name(key)) : [Any]"
            o += end()
            return o
        }
    }
    
    if let _ = value as? [NSNumber] {
        o += tab(i) + "let \(var_name(key)) : [NSNumber]"
    }
    
    if let _ = value as? Array<[String:Any]> {
        o += tab(i) + "let \(var_name(key)) : [\(class_name(key))]"
    }
    
    if let _ = value as? Array<String> {
        o += tab(i) + "let \(var_name(key)) : [String]"
    }
    
    if let _ = value as? [String:Any] {
        o += tab(i) + "let \(var_name(key)) : " + class_name(key)
    }
    
    if let _ = value as? NSNumber {
        o += tab(i) + "let \(var_name(key)) : NSNumber"
    }
    
    
    return o + end()
}

func decode(_ key:String,_ value:Any,_ i: Int) -> String {
    var o = tab(i)
    if let _ = value as? String {
        o += "self.\(var_name(key)) = value[\"\(key)\"] as? String ?? \"\""
    }
    
    if let _ = value as? [String:Any] {
        o += "self.\(var_name(key)) = \(class_name(key))(value[\"\(key)\"] as? [String:Any] ?? [:])"
    }
    
    if let _ = value as? NSNumber {
        o += "self.\(var_name(key)) = value[\"\(key)\"] as? NSNumber ?? NSNumber()"
    }
    
    if let value = value as? [Any] {
        if value.isEmpty {
            o += "self.\(var_name(key)) = value[\"\(key)\"] as? [Any] ?? []"
            o += end()
            return o
        }
    }
    
    if let _ = value as? [NSNumber] {
        o += "self.\(var_name(key)) = value[\"\(key)\"] as? [NSNumber] ?? []"
    }
    
    if let _ = value as? [String] {
        o += "self.\(var_name(key)) = value[\"\(key)\"] as? [String] ?? []"
    }
    
    if let _ = value as? [[String:Any]] {
        o += "self.\(var_name(key)) = (value[\"\(key)\"] as? [[String:Any]] ?? []).map(\(class_name(key)).init)"
    }
    
    return o + end()
}





func parse(key:String,_ value: Any,_ i:Int) -> String {
    
    var o = String()
    
    // create objects:
    if let value = value as? [String:Any] {
        o += tab(i) + "class \(class_name(key)) {" + end()
        for (key,value) in value {
            o += parse(key:key, value, i+1)
        }
    }
    
    if let value = value as? [Any] {
        o += parse(key: key, value.first ?? [], i+1)
    }
    
    // init
    if let value = value as? [String:Any] {
        
        for (key,value) in value {
            o += declare(key,value,i+1)
        }
        o += tab(i+1) + "init(_ value:[String:Any]){" + end()
        for (key,value) in value {
            o += decode(key,value,i+2)
        }
        o += tab(i+1) + "}" + end()
    }
    
    if let _ = value as? [String:Any] {
        o += tab(i) + "}" + end()
    }
    return o
}


let done = DispatchSemaphore(value: 0)
let session = URLSession(configuration: .default)

func process(_ name:String, _ data:Data){
    let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] ?? [:]
    print("// generated by sget")
    print("import Foundation")
    print(parse(key:name,jsonData ?? [:],0))
}

func get(urlString:String){
    let url = URL(fileURLWithPath: urlString)
    let name = url.pathComponents.last?.replacingOccurrences(of: ".", with: "")
    if let data = try? Data(contentsOf: url){
        process(name!, data)
        done.signal()
        return
    }
    
    if let interetURL = URL(string: urlString) {
        let request = URLRequest(url: interetURL)
        session.dataTask(with: request, completionHandler: { (data, urlResponse, error) in
            if let e = error {
                print("\(e)")
                done.signal()
                return
            }
            if let data = data {
                let name = url.pathComponents.last?.replacingOccurrences(of: ".", with: "")
                process(name!,data)
                done.signal()
            }
        }).resume()
    }
}

if CommandLine.arguments.count < 2 {
    print("Usage: json2swift <url1> <url2> ...")
    print("example: $ json2swift /path/to/file.json http://link.to/json")
} else {
    for item in 1..<CommandLine.arguments.count {
        get(urlString: CommandLine.arguments[item])
        done.wait()
    }
}