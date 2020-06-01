//
//  ZoomService.swift
//  swipe
//
//  Created by Masha Vodolazkaya on 29/04/2020.
//  Copyright © 2020 Paola Castro. All rights reserved.
//

import Foundation

private struct ZoomAPI {
    // SDK Info for using MobileRTC.
    static let domain = "zoom.us"
    static let appKey = "iI2YeTXYvN22xo1dluCPZzOdvaoh5CeNR4yN"
    static let appSecret = "FWmZVJrKqjGx7Fy1HTxDTS3wyidPY3QyWGMQ"
    
    // API User info for starting calls as API user.
    static let userID = ""
    static let userToken = ""
    
    // Default display name for meetings.
    static let defaultName = "Anonymous"
}

public struct ZoomMeeting {
    var number: Int
    var password: String = ""
    var topic: String?
    var startTime: Date?
    var timeZone: TimeZone?
    var durationInMinutes: UInt
}

// MARK: - ZoomService API Authentication

class ZoomService: NSObject, MobileRTCAuthDelegate {
    
    static let sharedInstance = ZoomService()

    var currentUserEmail = "nAn"
    
    var isAPIAuthenticated = false
    var isUserAuthenticated = false
    var userMeetings: [ZoomMeeting] = []
    
    // Authenticates user to use MobileRTC.
    func authenticateSDK() {
        let zoomSDK : MobileRTC = MobileRTC.shared()
        //    zoomSDK.mobileRTCDomain = ZoomAPI.domain // deprecated
        
        let context : MobileRTCSDKInitContext = MobileRTCSDKInitContext.init()
        context.domain = ZoomAPI.domain
        context.enableLog = true
        context.locale = MobileRTC_ZoomLocale.default
        
        //Note: This step is optional, Method is uesd for iOS Replaykit Screen share integration,if not,just ignore this step.
        context.appGroupId = "";
        let initializeResult = zoomSDK.initialize(context)
        Logger.log("zoom SDK initialized: \(initializeResult)")
        Logger.log("MobileRTC version: \(zoomSDK.mobileRTCVersion() ?? "NaN")")
        
        guard let authService: MobileRTCAuthService = zoomSDK.getAuthService() else { return }
        authService.delegate = self
        authService.clientKey = ZoomAPI.appKey
        authService.clientSecret = ZoomAPI.appSecret
        authService.sdkAuth()
        
        
    }
    
    // Handled by MobileRTCAuthDelegate, returns result of authenticateSDK function call.
    func onMobileRTCAuthReturn(_ returnValue: MobileRTCAuthError) {
        guard returnValue == MobileRTCAuthError_Success else {
            Logger.logHighPriority("Zoom: API authentication task failed, error code: \(returnValue.rawValue)")
            return
        }
        
        isAPIAuthenticated = true
        Logger.log("Zoom: API authentication task completed.")
    }
}


// MARK: - ZoomService Meeting Management

extension ZoomService {
    
    // Join a Zoom meeting.
    func joinMeeting(name: String = ZoomAPI.defaultName, number: Int64, password: String = "") {
        guard isAPIAuthenticated || isUserAuthenticated, let meetingService = MobileRTC.shared().getMeetingService() else { return }
        
        var paramDict: [String : String] = [
            kMeetingParam_Username : name,
            kMeetingParam_MeetingNumber : "\(number)",
            kMeetingParam_MeetingPassword : password
        ]
        
        
        let returnValue = meetingService.joinMeeting(with: paramDict)
        
        guard returnValue == MobileRTCMeetError_Success else {
            Logger.logHighPriority("Zoom: Join meeting task failed, error code: \(returnValue.rawValue)")
            return
        }
        
        Logger.log("Zoom: Join meeting task completed.")
    }
    
    // Start a Zoom meeting immediately.
    func startMeeting(name: String = ZoomAPI.defaultName, number: Int = -1, password: String = "") {
        guard isAPIAuthenticated || isUserAuthenticated, let meetingService = MobileRTC.shared().getMeetingService() else { return }
        
        var paramDict: [String : Any] = [kMeetingParam_Username : name]
        
        if isAPIAuthenticated && !isUserAuthenticated {
            paramDict[kMeetingParam_UserID] = ZoomAPI.userID
            paramDict[kMeetingParam_UserToken] = ZoomAPI.userToken
        }
        
        if number != -1 {
            paramDict[kMeetingParam_MeetingNumber] = "\(number)"
        }
        
        if password.count > 0 {
            paramDict[kMeetingParam_MeetingPassword] = password
        }
        
        let returnValue = meetingService.startMeeting(with: paramDict)
        
        guard returnValue == MobileRTCMeetError_Success else {
            Logger.logHighPriority("Zoom: Start meeting task failed, error code: \(returnValue.rawValue)")
            return
        }
        
        Logger.log("Zoom: Start meeting task completed.")
    }
}

// MARK: - ZoomService User + Meeting Scheduling Management

extension ZoomService: MobileRTCPremeetingDelegate {
    
    // Authenticate user as a Zoom member.
    func login(email: String, password: String) {
        guard isAPIAuthenticated else {
            Logger.error("API is not authenticated")
            return
        }
        guard let authService = MobileRTC.shared().getAuthService() else {
            Logger.error("failed to get Auth Service")
            return
        }
        authService.login(withEmail: email, password: password, rememberMe: true)
        currentUserEmail = email
        guard let preMeetingService = MobileRTC.shared().getPreMeetingService() else { return }
        preMeetingService.delegate = self
    }
    
    // Handled by MobileRTCPremeetingDelegate, returns result of login function call.
    func onMobileRTCLoginReturn(_ returnValue: Int) {
        guard returnValue == 0 else {
            Logger.logHighPriority("Zoom (User): Login task failed, error code: \(returnValue)")
            return
        }
        
        guard let authService = MobileRTC.shared().getAuthService() else {
            Logger.error("failed to get Auth Service")
            return
        }
        
        currentUserEmail = authService.getAccountInfo()?.getEmailAddress() as! String
        isUserAuthenticated = true
        Logger.log("Zoom (User): Login task completed.")
    }
    
    // Logout as Zoom member if user is authenticated as Zoom member.
    func logout() {
        guard isUserAuthenticated, let authService = MobileRTC.shared().getAuthService() else { return }
        authService.logoutRTC()
    }
    
    // Handled by MobileRTCPremeetingDelegate, returns result of logout function call.
    func onMobileRTCLogoutReturn(_ returnValue: Int) {
        guard returnValue == 0 else {
            Logger.logHighPriority("Zoom (User): Logout task failed, error code: \(returnValue)")
            return
        }
        
        isUserAuthenticated = false
        
        Logger.log("Zoom (User): Logout task completed.")
    }
    
    // Handled by MobileRTCPremeetingDelegate, prints a list of meetings the Zoom member has after scheduling, editing, or deleting a meeting.
    func sinkListMeeting(_ result: PreMeetingError, withMeetingItems array: [Any]) {
        guard result.rawValue == 0 else {
            Logger.logHighPriority("Zoom (User): List meeting task failed, error code: \(result)")
            return
        }
        
        userMeetings = []
        
        for meeting in array {
            if let meeting = meeting as? MobileRTCMeetingItem {
                let number = Int(meeting.getMeetingNumber())
                let password = meeting.getMeetingPassword() ?? ""
                let topic = meeting.getMeetingTopic()
                let startTime = meeting.getStartTime()
                
                let timeZone: TimeZone?
                if let timeZoneID = meeting.getTimeZoneID() {
                    timeZone = TimeZone(abbreviation: timeZoneID)
                } else {
                    timeZone = nil
                }
                
                let durationInMinutes = meeting.getDurationInMinutes()
                let zoomMeeting = ZoomMeeting(number: number, password: password, topic: topic, startTime: startTime, timeZone: timeZone, durationInMinutes: durationInMinutes)
                userMeetings.append(zoomMeeting)
            }
        }
        
        Logger.log("\nZoom (User): Found \(userMeetings.count) meetings.")
        
        for (index, meeting) in userMeetings.enumerated() {
            Logger.log("\n\(index + 1). Meeting number: \(meeting.number)")
            
            if meeting.password.count > 0 {
                Logger.log("   Meeting password: \(meeting.password)")
            }
            
            if meeting.topic != nil {
                Logger.log("   Meeting Topic: \(meeting.topic!)")
            } else {
                Logger.log("   Meeting Topic: <NO TOPIC>")
            }
            
            if meeting.startTime != nil {
                Logger.log("   Meeting Start Time: \(meeting.startTime!)")
            } else {
                Logger.log("   Meeting Start Time: <NO START TIME>")
            }
            
            if meeting.timeZone != nil {
                Logger.log("   Meeting Time Zone: \(meeting.timeZone!)")
            } else {
                Logger.log("   Meeting Time Zone: <NO TIME ZONE>")
            }
            
            Logger.log("   Meeting Duration: \(meeting.durationInMinutes) minute(s)")
        }
        
    }
    
    // Schedule a Zoom meeting as a Zoom member.
    func scheduleMeeting(topic: String, startTime: Date, timeZone: TimeZone = NSTimeZone.local, durationInMinutes: TimeInterval) {
        guard isUserAuthenticated else {
            Logger.error("user is not authenticated")
            return
        }
        guard let preMeetingService = MobileRTC.shared().getPreMeetingService() else {
            Logger.error("failed creating preMeetingService")
            return
        }
        guard let meeting = preMeetingService.createMeetingItem() else {
            Logger.error("failed creating meeting item")
            return
        }
        
        preMeetingService.delegate = self
        meeting.setMeetingTopic(topic)
        meeting.setStartTime(startTime)
        meeting.setTimeZoneID(timeZone.abbreviation() ?? "")
        meeting.setDurationInMinutes(UInt(durationInMinutes))
        
        
        preMeetingService.scheduleMeeting(meeting, withScheduleFor: currentUserEmail)
        preMeetingService.destroy(meeting)
    }
    
    // Handled by MobileRTCPremeetingDelegate, returns result of scheduleMeeting function call.
    func sinkSchedultMeeting(_ result: PreMeetingError, meetingUniquedID uniquedID: UInt64) {
        guard result.rawValue == 0 else {
            Logger.logHighPriority("Zoom (User): Schedule meeting task failed, error code: \(result)")
            return
        }
        
        Logger.log("Zoom (User): Schedule meeting task completed.")
    }
    
    // Edit an existing Zoom meeting as a Zoom member by providing a ZoomMeeting object.
    func editMeeting(_ zoomMeeting: ZoomMeeting, topic: String? = nil, startTime: Date? = nil, timeZone: TimeZone? = nil, durationInMinutes: TimeInterval? = nil) {
        editMeeting(number: zoomMeeting.number, topic: topic, startTime: startTime, timeZone: timeZone, durationInMinutes: durationInMinutes)
    }
    
    // Edit an existing Zoom meeting as a Zoom member by providing a Zoom meeting number.
    func editMeeting(number: Int, topic: String? = nil, startTime: Date? = nil, timeZone: TimeZone? = nil, durationInMinutes: TimeInterval? = nil) {
        guard isUserAuthenticated, let preMeetingService = MobileRTC.shared().getPreMeetingService(), let meeting = preMeetingService.getMeetingItem(byUniquedID: UInt64(UInt(number))) else { return }
        
        if let topic = topic {
            meeting.setMeetingTopic(topic)
        }
        
        if let startTime = startTime {
            meeting.setStartTime(startTime)
        }
        
        if let timeZone = timeZone {
            meeting.setTimeZoneID(timeZone.abbreviation() ?? "")
        }
        
        if let durationInMinutes = durationInMinutes {
            meeting.setDurationInMinutes(UInt(durationInMinutes))
        }
        
        preMeetingService.editMeeting(meeting)
    }
    
    // Handled by MobileRTCPremeetingDelegate, returns result of editMeeting function call.
    func sinkEditMeeting(_ result: PreMeetingError, meetingUniquedID uniquedID: UInt64) {
        guard result.rawValue == 0 else {
            Logger.logHighPriority("Zoom (User): Edit meeting task failed, error code: \(result.rawValue)")
            return
        }
        
        Logger.log("Zoom (User): Edit meeting task completed.")
    }
    
    // Delete an existing event as a Zoom member by providing a ZoomMeeting object.
    func deleteMeeting(_ zoomMeeting: ZoomMeeting) {
        deleteMeeting(number: zoomMeeting.number)
    }
    
    // Delete an existing event as a Zoom member by providing a Zoom meeting number.
    func deleteMeeting(number: Int) {
        guard isUserAuthenticated, let preMeetingService = MobileRTC.shared().getPreMeetingService(), let meeting = preMeetingService.getMeetingItem(byUniquedID: UInt64(UInt(number))) else { return }
        preMeetingService.deleteMeeting(meeting)
    }
    
    // Handled by MobileRTCPremeetingDelegate, returns result of deleteMeeting function call.
    
    func sinkDeleteMeeting(_ result: PreMeetingError) {
        guard result.rawValue == 0 else {
            Logger.logHighPriority("Zoom (User): Delete meeting task failed, error code: \(result.rawValue)")
            return
        }
        
        Logger.log("Zoom (User): Delete meeting task completed.")
    }
}

