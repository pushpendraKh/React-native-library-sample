//
//  HTOrderTrackingUseCaseViewModel.swift
//  HyperTrack
//
//  Created by Atul Manwar on 13/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import CoreLocation

@objc public protocol HTOrderTrackingUseCaseViewModelProtocol: HTBaseTrackingViewModelProtocol {
    func mapToTrackingUseCase(actions: [HTTrackAction]) -> HTOrderTrackingUseCase.OrderData
}

@objc public class HTOrderTrackingUseCaseViewModel: HTBaseTrackingViewModel, HTOrderTrackingUseCaseViewModelProtocol {
    public func mapToTrackingUseCase(actions: [HTTrackAction]) -> HTOrderTrackingUseCase.OrderData {
        let data = HTOrderTrackingUseCase.OrderData.default
        guard actions.count > 0  else {
            data.isTrackingEnabled = false
            return data
        }
        let uncompletedActions = actions.filter({ !$0.actionStatus.isCompleted })
        data.isTrackingEnabled = (uncompletedActions.count > 0)
        if data.isTrackingEnabled {
            let firstAction = uncompletedActions[0]
            let headerCard: HTComponentProtocol! = HTUserTrackingBottomCard.Data.UserCard(imageUrl: nil, title: firstAction.user?.name ?? "", description: firstAction.uniqueId.isEmpty ? "Deliverying Order" : "Order | \(firstAction.uniqueId)", actionText: "CALL", actionImage: UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.call), actionType: firstAction.user?.phone?.isEmpty == false ? HTBottomViewActionData(type: .call, data: firstAction.user?.phone) : HTBottomViewActionData(type: .none), isCurrent: true, type: .user)
            //        trackingInfo = HTLiveTrackingUseCase.TrackingInfo(trackingUrl: trackingUrl, currentActionId: currentActionId)
            data.bottomViewData = [headerCard]
            var annotations = HTAnnotationDataAdapter.mapActionsToUserAnnotations(actions, currentUserId: HyperTrack.getUserId())
            let expectedPlaceAnnotations = HTAnnotationDataAdapter.getExpectedPlaceAnnotations(actions)
            annotations.append(contentsOf: expectedPlaceAnnotations)
            if !expectedPlaceAnnotations.isEmpty {
                data.isExpectedPlaceSet = true
            }
            data.mapData = HTMapData(annotations: annotations, polylines: HTPolylineAdapter.getPolylineData(actions))
        } else if let lastAction = actions.last {
            let header = HTOrderTrackingBottomCard.Data.OrderStatus(title: "Order Completed", image: UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.checkmark), type: .orderStatus)
            let distanceInfo = HTOrderTrackingBottomCard.Data.OrderInfo(title: "DISTANCE", description: HTSpaceTimeUtil.instance.getReadableDistance(Double(lastAction.distance), roundedTo: 1, unit: lastAction.display?.distanceUnitType ?? .km), type: .orderInfo)
            let timeInfo = HTOrderTrackingBottomCard.Data.OrderInfo(title: "DURATION", description: HTSpaceTimeUtil.instance.getReadableDate(lastAction.duration ?? 0), type: .orderInfo)
            let tripIdInfo = HTOrderTrackingBottomCard.Data.OrderInfo(title: "TRIP ID", description: lastAction.uniqueId, type: .orderInfo)
            let driverInfo = HTOrderTrackingBottomCard.Data.OrderInfo(title: "DRIVER NAME", description: "\(lastAction.user?.name ?? "")", type: .orderInfo)
            let infoArray = HTOrderTrackingBottomCard.Data.OrderInfoArray(values: [distanceInfo, timeInfo, tripIdInfo, driverInfo], title: "", type: .orderInfoArray)
            data.bottomViewData = [header, infoArray]

            var coordinates = CLLocationCoordinate2D.zero
            
            if let lat = lastAction.startedPlace?.location?.coordinates.last, let lng = lastAction.startedPlace?.location?.coordinates.first {
                coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            } else if let coordinate = lastAction.location?.geojson?.coordinates, let lat = coordinate.last, let lng = coordinate.first {
                coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
            var annotations: [HTAnnotationData] = [
                HTAnnotationDataAdapter.mapActionToUserAnnotation(lastAction, coordinates: coordinates, isCurrentUser: lastAction.user?.id == HyperTrack.getUserId())
            ]
            let expectedPlaceAnnotations = HTAnnotationDataAdapter.getExpectedPlaceAnnotations(actions)
            annotations.append(contentsOf: expectedPlaceAnnotations)
            if !expectedPlaceAnnotations.isEmpty {
                data.isExpectedPlaceSet = true
            }
            data.mapData =
                HTMapData(annotations: annotations, polylines: HTPolylineAdapter.getPolylineData(actions))
        }
        data.shouldShowCurrentLocation = (actions.filter({ $0.user?.id == HyperTrack.getUserId() }).count > 0)
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

