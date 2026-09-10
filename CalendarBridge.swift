import Foundation
import EventKit

struct BridgeRequest: Decodable {
 let action:String
 var start:Double?; var end:Double?; var calendarIds:[String]?; var calendarId:String?; var tasks:[PlanEvent]?
}
struct PlanEvent:Decodable { let id:String; let title:String; let start:Double; let end:Double; let reminder:Int; var eventId:String? }
@main struct CalendarBridge {
 static func emit(_ value:[String:Any]) {if let d=try? JSONSerialization.data(withJSONObject:value),let s=String(data:d,encoding:.utf8){print(s)}}
 static func main() async {
  do {
   let req=try JSONDecoder().decode(BridgeRequest.self,from:FileHandle.standardInput.readDataToEndOfFile())
   let store=EKEventStore()
   if req.action=="connect" {let granted=try await store.requestFullAccessToEvents();emit(["authorized":granted]);return}
   let authorized=EKEventStore.authorizationStatus(for:.event) == .fullAccess
   if req.action=="status" {emit(["authorized":authorized]);return}
   guard authorized else {emit(["error":"Calendar access is not enabled. Press Connect and allow access in the macOS prompt."]);return}
   if req.action=="calendars" {
    let calendars=store.calendars(for:.event).map { c in ["id":c.calendarIdentifier,"title":c.title,"source":c.source.title,"writable":c.allowsContentModifications] as [String:Any] }
    emit(["calendars":calendars]);return
   }
   if req.action=="events" {
    guard let start=req.start,let end=req.end,end>start,end-start<=35*86400000,let ids=req.calendarIds,ids.count<=50 else {emit(["error":"Select calendars and a date range of at most 35 days."]);return}
    let calendars=store.calendars(for:.event).filter{ids.contains($0.calendarIdentifier)}
    if calendars.isEmpty {emit(["events":[]]);return}
    let predicate=store.predicateForEvents(withStart:Date(timeIntervalSince1970:start/1000),end:Date(timeIntervalSince1970:end/1000),calendars:calendars)
    let events=store.events(matching:predicate).filter{$0.status != .canceled}.prefix(2000).map { e -> [String:Any] in
     let taskId=e.url?.scheme=="alittleeasier" ? e.url?.lastPathComponent ?? "" : ""
     return ["id":e.eventIdentifier ?? UUID().uuidString,"title":e.title ?? "Calendar event","start":e.startDate.timeIntervalSince1970*1000,"end":e.endDate.timeIntervalSince1970*1000,"allDay":e.isAllDay,"calendarId":e.calendar.calendarIdentifier,"busy":e.availability != .free,"taskId":taskId]
    }
    emit(["events":events]);return
   }
   if req.action=="publish" {
    guard let id=req.calendarId,let calendar=store.calendar(withIdentifier:id),calendar.allowsContentModifications,let tasks=req.tasks,tasks.count<=100 else {emit(["error":"Choose a writable destination calendar and up to 100 timed tasks."]);return}
    var events:[(EKEvent,String)]=[]
    for t in tasks {
     guard !t.title.isEmpty,t.title.count<=500,t.end>t.start,t.end-t.start<=86400000,t.reminder>=0,t.reminder<=1440,UUID(uuidString:t.id) != nil else {emit(["error":"A task has invalid dates, title or reminder."]);return}
     let marker=URL(string:"alittleeasier://task/"+t.id)!
     let event:EKEvent
     if let old=t.eventId,!old.isEmpty {
      guard let existing=store.event(withIdentifier:old),existing.url==marker,existing.calendar.calendarIdentifier==id else {emit(["error":"A previously linked calendar event was moved or removed. Resolve it in Calendar before publishing this task again."]);return}
      event=existing
     } else {
      let nearby=store.predicateForEvents(withStart:Date(timeIntervalSince1970:t.start/1000-86400),end:Date(timeIntervalSince1970:t.end/1000+86400),calendars:[calendar])
      event=store.events(matching:nearby).first(where:{$0.url==marker}) ?? EKEvent(eventStore:store)
     }
     event.title=t.title;event.startDate=Date(timeIntervalSince1970:t.start/1000);event.endDate=Date(timeIntervalSince1970:t.end/1000);event.calendar=calendar;event.url=marker
     event.notes="Planned with A little easier. Times are flexible."
     event.alarms=[EKAlarm(relativeOffset:Double(-t.reminder*60))]
     events.append((event,t.id))
    }
    do {for (event,_) in events {try store.save(event,span:.thisEvent,commit:false)};try store.commit()} catch {store.reset();throw error}
    emit(["published":events.map{["taskId":$0.1,"eventId":$0.0.eventIdentifier ?? ""]}]);return
   }
   emit(["error":"Unknown calendar operation."])
  } catch {emit(["error":"Calendar operation could not finish. Check macOS Calendar permissions and try again."])}
 }
}
