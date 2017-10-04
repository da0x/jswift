// Copyright 1017 Daher Alfawares & Ricky Powell
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0

import Foundation

struct context {
    let current_type : String
    let level        : Int
    let value        : Any
    
    func next(type:String, value:Any) -> context {
        return context(
            current_type: type,
            level: level + 1,
            value: value
        )
    }
}

func app() -> String {
    return "jswift"
}

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

func symbol(_ key:String) -> String {
    return key
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "-", with: "_")
}

func class_name(_ key:String) -> String {
    return symbol(key.capitalized)
}

func class_name(_ url:URL) -> String {
    return url.pathComponents.last?
        .replacingOccurrences(of: ".json", with: "")
        .replacingOccurrences(of: "-", with: "_")
        .components(separatedBy: "?").first ?? "Generic"
}

func var_name(_ key:String) -> String {
    var string = ""
    guard key != key.uppercased() else {
        return symbol(key.lowercased())
    }
    for (i, value) in key.characters.enumerated() {
        if i == 0 {
            string += String(value).lowercased()
        }
        else {
            string += String(value)
        }
    }
    
    return symbol(string)
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

func encode(_ key:String,_ value:Any,_ i: Int) -> String {
    var o = tab(i)
    
    if let _ = value as? [String:Any] {
        o += "map[\"\(key)\"] = self.\(var_name(key)).map()"
    } else if let value = value as? [[String:Any]] {
        if value.isEmpty {
            o += "map[\"\(key)\"] = self.\(var_name(key))"
        } else {
            o += "map[\"\(key)\"] = self.\(var_name(key)).map(){$0.map()}"
        }
    } else {
        o += "map[\"\(key)\"] = self.\(var_name(key)) as Any"
    }
    return o + end()
}

func parse(_ context:context) -> String {
    let key = context.current_type
    let value = context.value
    let i = context.level
    var o = String()
    
    // create objects:
    if let value = value as? [String:Any] {
        o += tab(i) + "class \(class_name(key)): jswift {" + end()
        for (key,value) in value {
            o += parse(context.next(type: key, value: value))
        }
    }
    
    if let value = value as? [Any] {
        guard value.count > 0 else { return "" }
        
        o += parse(context.next(type: key, value: value.first ?? []))
    }
    
    // init
    if let value = value as? [String:Any] {
        
        for (key,value) in value {
            o += declare(key,value,i+1)
        }
        o += tab(i+1) + "required init(_ value:[String:Any]){" + end()
        for (key,value) in value {
            o += decode(key,value,i+2)
        }
        o += tab(i+1) + "}" + end()
        
        o += tab(i+1) + "func map() -> [String:Any]{" + end()
        o += tab(i+2) + "var map = [String:Any]()" + end()
        for (key,value) in value {
            o += encode(key,value,i+2)
        }
        o += tab(i+2) + "return map" + end()
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
    
    print("// generated by \(app())")
    print("import Foundation")
    print("protocol jswift {")
    print("    init(_ value: [String:Any])")
    print("    func map() -> [String:Any]")
    print("}")
    
    var parse_context : context?
    
    if let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] {
        parse_context = context(current_type: name, level: 0, value: jsonData as Any)
    } else if let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
        parse_context = context(current_type: name, level: -1, value: jsonArray as Any)
    }
    
    
    print(parse(parse_context!))
}

func get(urlString:String){
    let url = URL(fileURLWithPath: urlString)
    let name = class_name(url)
    
    if let data = try? Data(contentsOf: url){
        process(name, data)
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
                let name = class_name(url)
                process(name,data)
                done.signal()
            }
        }).resume()
    }
}

if CommandLine.arguments.count < 2 {
    print("Usage: \(app()) <url1> <url2> ...")
    print("example: $ \(app()) /path/to/file.json http://link.to/json")
    print("executed as: " + CommandLine.arguments.first!)
} else {
    for item in 1..<CommandLine.arguments.count {
        get(urlString: CommandLine.arguments[item])
        done.wait()
    }
}

