import Foundation
import FoundationModels
struct Request: Decodable { let system: String; let prompt: String; let kind: String }
@main struct LocalPlanner {
    static func main() async {
        guard #available(macOS 26.0, *) else { emit(["error":"macOS 26 or later is required."]); return }
        if CommandLine.arguments.contains("--status") {
            switch SystemLanguageModel.default.availability {
            case .available: emit(["ready":true])
            case .unavailable(let reason): emit(["ready":false,"reason":String(describing:reason)])
            }
            return
        }
        do {
            let request = try JSONDecoder().decode(Request.self, from: FileHandle.standardInput.readDataToEndOfFile())
            let item = DynamicGenerationSchema(name:"Item", properties:[
                .init(name:"text", description:"A specific action or original thought. Name the object and the intended result.", schema:.init(type:String.self)),
                .init(name:"category", schema:.init(name:"Category", anyOf:["Action","Idea","Question","Note"])),
                .init(name:"minutes", description:"Realistic active-work minutes. For Action, consider each action separately, often 5 to 60 minutes. For Note, Idea or Question use 1.", schema:.init(type:Int.self, guides:[.range(1...240)]))
            ])
            let plan = DynamicGenerationSchema(name:"Plan", properties:[
                .init(name:"items", description:"Distinct suggestions in logical order, based only on the user input.", schema:.init(arrayOf:item,minimumElements:1,maximumElements:request.kind == "breakdown" ? 6 : 12)),
                .init(name:"assumptions", description:"Only missing practical logistics. Empty string if none. Never interpret feelings or health.", schema:.init(type:String.self))
            ])
            let schema = try GenerationSchema(root:plan,dependencies:[])
            let session = LanguageModelSession(instructions:request.system)
            var finalPrompt = request.prompt
            if request.kind == "breakdown" {
                _ = try await session.respond(to: request.prompt + "\nBefore the structured checklist, write a concrete draft plan in 4 to 6 numbered lines, each with its own plausible time. Only the first step must be very short. Use the stated materials. Include the actual work and a concrete finishing action. Avoid redundant review steps.", options: GenerationOptions(temperature: 0.3))
                finalPrompt = "Convert your draft plan into the structured checklist. Keep its specific actions and individual times. Do not replace all durations with the first step's time. Use Action as each category. No more than six steps."
            }
            let response = try await session.respond(to:finalPrompt,schema:schema,options:GenerationOptions(temperature:0.2))
            print(response.content.jsonString)
        } catch { emit(["error":"Apple Intelligence could not finish locally. Try a shorter or more specific task.","detail":String(describing:error)]) }
    }
    static func emit(_ object:[String:Any]) { if let data=try? JSONSerialization.data(withJSONObject:object),let value=String(data:data,encoding:.utf8){print(value)} }
}
