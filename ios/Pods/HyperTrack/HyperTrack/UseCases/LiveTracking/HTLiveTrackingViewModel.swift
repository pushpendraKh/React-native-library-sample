//
//  HTLiveTrackingViewModel.swift
//  HyperTrack
//
//  Created by Atul Manwar on 08/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import CoreLocation

public typealias HTActionCompletionHandler = (HTAction?, HTError?) -> Void
public typealias HTActionArrayCompletionHandler = ([HTAction]?, HTError?) -> Void
public typealias HTTrackActionCompletionHandler = (HTTrackAction?, HTError?) -> Void
public typealias HTTrackActionArrayCompletionHandler = ([HTTrackAction]?, HTError?) -> Void

@objc public protocol HTBaseViewModelProtocol: class {
}

extension HTBaseViewModelProtocol {
//    public func mapToResponse<T>(_ object: T?, error: HTError?) -> HTAPIResponse<T> {
//        if let error = error {
//            return .failure(error)
//        } else if let object = object {
//            return .success(object)
//        } else {
//            return HTAPIResponse<T>.unknownFailure
//        }
//    }
}

@objc public protocol HTLiveTrackingUseCaseViewModelProtocol: HTBaseTrackingViewModelProtocol {
    var trackingInfo: HTLiveTrackingUseCase.TrackingInfo { get set }
    func mapToLiveTrackingUseCase(actions: [HTTrackAction]) -> HTLiveTrackingUseCase.LiveData
    func mapToLiveTrackingUseCase(actions: [HTTrackAction], completionHandler: @escaping ((HTLiveTrackingUseCase.LiveData) -> Void))
}

@objc public class HTLiveTrackingUseCaseViewModel: HTBaseTrackingViewModel, HTLiveTrackingUseCaseViewModelProtocol {
    public var trackingInfo = HTLiveTrackingUseCase.TrackingInfo.default
    
    public func mapToLiveTrackingUseCase(actions: [HTTrackAction], completionHandler: @escaping ((HTLiveTrackingUseCase.LiveData) -> Void)) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let data = self?.mapToLiveTrackingUseCase(actions: actions) else { return }
            completionHandler(data)
        }
    }
    
    public func mapToLiveTrackingUseCase(actions: [HTTrackAction]) -> HTLiveTrackingUseCase.LiveData {
        let data = HTLiveTrackingUseCase.LiveData.default
        guard actions.count > 0  else {
            data.isTrackingEnabled = false
            return data
        }
        data.isTrackingEnabled = (actions.filter({ !$0.actionStatus.isCompleted }).count > 0)
        let firstAction = actions[0]
        if let _ = firstAction.expectedPlace {
            data.isExpectedPlaceSet = true
        }
        data.mapData = HTMapDataAdapter.getMapData(actions)
        let users = actions.flatMap({ $0.user })
        let currentUserAction = actions.filter({ $0.user?.id == HyperTrack.getUserId() }).first
        if let mockTracking = currentUserAction?.metadata["mock_tracking"] as? Bool {
            data.showCurrentLocation = !mockTracking
        }
        data.isCompleted = (currentUserAction?.actionStatus.isCompleted == true)
        let trackingUrl = firstAction.trackingUrl
        if actions.count == 1 && !data.isTrackingEnabled {
            let header = HTOrderTrackingBottomCard.Data.OrderStatus(title: "Trip Completed", image: UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.checkmark), type: .orderStatus)
            let distanceInfo = HTOrderTrackingBottomCard.Data.OrderInfo(title: "DISTANCE", description: HTSpaceTimeUtil.instance.getReadableDistance(Double(firstAction.distance), roundedTo: 1, unit: firstAction.display?.distanceUnitType ?? .km), type: .orderInfo)
            let timeInfo = HTOrderTrackingBottomCard.Data.OrderInfo(title: "DURATION", description: HTSpaceTimeUtil.instance.getReadableDate(firstAction.duration ?? 0), type: .orderInfo)
            let infoArray = HTOrderTrackingBottomCard.Data.OrderInfoArray(values: [timeInfo, distanceInfo], title: "", type: .orderInfoArray)
            data.bottomViewData = [header, infoArray]
        } else {
            let headerCard: HTComponentProtocol!
            if users.count == 1 {
                let isCurrentUser = (currentUserAction != nil)
                headerCard = HTUserTrackingBottomCard.Data.UserCard(imageUrl: nil, title: isCurrentUser ? "TRACKED BY" : currentUserAction?.user?.name ?? "", description: "0 people", actionText: "SHARE", actionImage: UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.share), actionType: HTBottomViewActionData(type: .share), isCurrent: true, type: .user)
            } else {
                let title = getUserNames(users, currentUser: currentUserAction?.user)
                headerCard = HTUserTrackingBottomCard.Data.UserCard(imageUrl: nil, title: title.isEmpty ? "TRACKED BY" : title, description: users.count == 2 ? "1 person" : "\(users.count - 1) people", actionText: "SHARE", actionImage: UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.share), actionType: HTBottomViewActionData(type: .share), isCurrent: true, type: .user)
            }
            var details: [HTComponentProtocol] = actions.map({
                let userInfo = HTAnnotationDataAdapter.getStatusInfo($0)
                let isPhoneNumberAvailable = ($0.user?.phone?.isEmpty == false && $0.user?.phone != nil)
                return HTUserTrackingBottomCard.Data.UserCard(imageUrl: $0.user?.photo, title: ($0.user?.id == currentUserAction?.user?.id) ? "You" : $0.user?.name ?? "User", description: userInfo.title, actionText: isPhoneNumberAvailable ? "CALL" : "", actionImage: isPhoneNumberAvailable ? UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.call) : nil, actionType: isPhoneNumberAvailable ? HTBottomViewActionData(type: .call, data: $0.user?.phone) : HTBottomViewActionData(type: .none), isCurrent: ($0.user?.id == currentUserAction?.user?.id), type: .userDetails)
            })
            details.insert(headerCard, at: 0)
            if let action = currentUserAction, !action.actionStatus.isCompleted {
                let statusCard: HTComponentProtocol = HTUserTrackingBottomCard.Data.Status(title: "SHARING YOUR LIVE LOCATION", actionText: "STOP", actionType: HTBottomViewActionData(type: .stopSharing, data: action.id), type: .status)
                details.append(statusCard)
            }
            data.bottomViewData = details
        }
        let currentCollectionId = currentUserAction?.collectionId ?? ""
        let eta = currentUserAction?.eta?.toString(dateFormat: Locale.timeFormat) ?? ""
        trackingInfo = HTLiveTrackingUseCase.TrackingInfo(trackingUrl: trackingUrl, collectionId: currentCollectionId, eta: eta)
        return data
    }
    
    fileprivate func getUserNames(_ users: [HTUser], currentUser: HTUser?) -> String {
        let separator = ", "
        let usersWithNames = users.flatMap({ $0.name }).filter({ $0.isEmpty })
        let lastUserName = usersWithNames.last ?? ""
        let currentUserName = currentUser?.name ?? ""
        return usersWithNames.joined(separator: separator).replacingOccurrences(of: currentUserName, with: "You").replacingOccurrences(of: (separator + lastUserName), with: (" and " + lastUserName))
    }
}
