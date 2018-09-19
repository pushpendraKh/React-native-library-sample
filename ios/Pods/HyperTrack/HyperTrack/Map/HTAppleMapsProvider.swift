//
//  HTAppleMapsProvider.swift
//  HyperTrack
//
//  Created by Atul Manwar on 28/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import MapKit

@objc public protocol HTMapsProviderProtocol: HTMapViewDelegate {
    var updatesDelegate: HTMapViewUpdatesDelegate? { get set }
    var contentView: UIView { get }
    func centerMapOnAllAnnotations(_ animated: Bool)
}

public final class HTAppleMapsProvider: NSObject {
    private (set) var mapView: MKMapView {
        didSet {
            mapView.showsPointsOfInterest = false
        }
    }
    public var contentView: UIView {
        return mapView
    }
    public var showCurrentLocation: Bool = true {
        didSet {
            mapView.showsUserLocation = showCurrentLocation
            if showCurrentLocation && mapView.annotations.count <= 1 {
                centerMapAtCoordinate(mapView.userLocation.coordinate, span: 0.005)
            }
        }
    }
    fileprivate var lastUpdatedDate: Date = Date.distantPast
    fileprivate var locatedUser = false
    fileprivate var annotationMap: [String: HTAnnotation] = [:]
    fileprivate var debouncedOperation: HTDebouncer?
    fileprivate var disableMapZoomForCount = 0
    fileprivate var lastCoordinate = CLLocationCoordinate2D.zero
    fileprivate var zoomAllowed: Bool {
        if disableMapZoomForCount > 0 {
            disableMapZoomForCount -= 1
        }
        return (disableMapZoomForCount == 0)
    }
    public weak var updatesDelegate: HTMapViewUpdatesDelegate?
    
    init(_ delegate: MKMapViewDelegate? = nil) {
        mapView = MKMapView(frame: .zero)
        mapView.showsUserLocation = showCurrentLocation
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        mapView.showsCompass = false
        mapView.showsScale = false
        super.init()
        mapView.delegate = (delegate ?? self)
        debouncedOperation = HTDebouncer(delay: 0.5, callback: { [weak self] in
            guard self?.locatedUser == true else { return }
            self?.centerMapOnAllAnnotationsInternal(true)
        })
    }
}

extension HTAppleMapsProvider {
    fileprivate func createPolyLine(_ coordinates: [CLLocationCoordinate2D]) -> MKPolyline {
        let overlay = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.add(overlay, level: .aboveRoads)
        return overlay
    }
    
    fileprivate func addDestinationPolyline(_ lat: Double, lng: Double) {
        _ = createPolyLine([mapView.userLocation.coordinate, CLLocationCoordinate2D(latitude: lat, longitude: lng)])
    }
    
    fileprivate func centerMapAtCoordinate(_ coordinate: CLLocationCoordinate2D, span: Double) {
        guard CLLocationCoordinate2DIsValid(coordinate) else { return }
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span))
        mapView.setRegion(region, animated: true)
    }
    
    fileprivate func centerMapWithCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
        var rect = MKMapRectNull
        for coordinate in coordinates {
            let point = MKMapPointForCoordinate(coordinate)
            rect = MKMapRectUnion(rect, MKMapRect(origin: point, size: MKMapSize(width: 0, height: 0)))
        }
        UIView.animate(withDuration: HTProvider.animationDuration, delay: 0, options: .curveEaseOut, animations: {
            self.mapView.setVisibleMapRect(rect, edgePadding: self.mapView.layoutMargins, animated: true)
        }, completion: nil)
    }
    
    public func centerMapOnAllAnnotations(_ animated: Bool) {
        UIView.animate(withDuration: animated ? HTProvider.animationDuration : 0, delay: 0, options: .allowUserInteraction, animations: {
            self.mapView.showAnnotations(self.mapView.annotations, animated: animated)
        }, completion: nil)
    }
    
    fileprivate func centerMapOnAllAnnotationsInternal(_ animated: Bool) {
        guard zoomAllowed && locatedUser else { return }
        centerMapOnAllAnnotations(animated)
    }
}

extension HTAppleMapsProvider: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !locatedUser {
            centerMapAtCoordinate(userLocation.coordinate, span: 0.005)
        } else if showCurrentLocation {
            centerMapOnAllAnnotations(true)
        }
        if let view = mapView.view(for: userLocation) as? HTAnnotationView {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                guard let `self` = self else { return }
                view.rotateForBearing(CGFloat(HTMapUtils.headingFrom(self.lastCoordinate, next: userLocation.coordinate) * Double.pi / 180.0))
            }, completion: nil)
        }
        lastCoordinate = userLocation.coordinate
    }
    
    public func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if !locatedUser {
            mapView.showAnnotations(mapView.annotations, animated: true)
        }
        locatedUser = true
    }
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            if let marker = mapView.dequeueReusableAnnotationView(withIdentifier: "currentLocation") as? HTAnnotationView {
//                marker.applyStyles([
//                    .color(HTProvider.style.colors.brand),
//                    ])
                return marker
            } else {
                let marker = HTAnnotationView(annotation: annotation, reuseIdentifier: "currentLocation", data: HTAnnotationData(id: "currentLocation", coordinate: mapView.userLocation.coordinate, metaData: HTAnnotationData.MetaData(isPulsating: true, type: .currentUser, actionInfo: nil), callout: nil))
//                marker.applyStyles([
//                    .color(HTProvider.style.colors.brand),
//                    ])
                marker.annotation = annotation
                return marker
            }
        } else if let htAnnotation = annotation as? HTAnnotation {
            let id = htAnnotation.data?.id ?? "placeMarker"
            if let marker = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? HTAnnotationView {
                marker.data = htAnnotation.data
                marker.annotation = annotation
                return marker
            } else {
                let marker = HTAnnotationView(annotation: annotation, reuseIdentifier: id, data: htAnnotation.data)
                return marker
            }
        } else {
            return MKAnnotationView()
        }
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        if let polyline = overlay as? HTPolyline {
            if polyline.data?.type == .dotted {
                renderer.strokeColor = HTProvider.style.colors.brand
                renderer.lineCap = .round
                renderer.lineWidth = 2
                renderer.lineDashPattern = [2, 4]
            } else {
                renderer.strokeColor = HTProvider.style.colors.brand
                renderer.lineCap = .round
                renderer.lineWidth = 2
            }
        }
        return renderer
    }
    
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        (mapView.subviews.first?.gestureRecognizers ?? []).forEach({
            if $0.state == .began || $0.state == .ended {
                disableMapZoomForCount = 5
            }
        })
    }
    
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        updatesDelegate?.mapViewDidChange(centerCoordinate: mapView.convert(mapView.center, toCoordinateFrom: nil))
    }
}

extension HTAppleMapsProvider: HTMapsProviderProtocol {
    public func cleanUp() {
        mapView.annotations.forEach({ (mapView.view(for: $0) as? HTAnnotationView)?.data = nil })
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        annotationMap.removeAll()
        if showCurrentLocation && mapView.annotations.count <= 1 {
            centerMapAtCoordinate(mapView.userLocation.coordinate, span: 0.005)
            if let view = mapView.view(for: mapView.userLocation) as? HTAnnotationView {
                view.data = HTAnnotationData(id: "currentLocation", coordinate: mapView.userLocation.coordinate, metaData: HTAnnotationData.MetaData(isPulsating: true, type: .currentUser, actionInfo: nil), callout: nil)
            }
        }
//        centerMapAtCoordinate(mapView.userLocation.coordinate, span: 0.005)
    }
    
    public func addAnnotations(_ data: [HTAnnotationData]) {
        let newAnnotationIds = data.map({ $0.id })
        let oldAnnotationIds = annotationMap.keys
        let forDeletion: [HTAnnotation] = oldAnnotationIds.flatMap({ (value) -> HTAnnotation? in
            if !newAnnotationIds.contains(value) {
                guard let annotation = self.annotationMap[value] else { return nil }
                guard let view = mapView.view(for: annotation) as? HTAnnotationView else { return nil }
                view.data = nil
                return annotation
            } else {
                return nil
            }
        })
        mapView.removeAnnotations(forDeletion)
//        var lastCoordinatesForAnnotation: [String: CLLocationCoordinate2D?] = [:]
//        let trailingPolylineData: [HTTimeAwarePolyline] = data.flatMap({
//            let slice = $0.locationTimeSeries?.slice(HTProvider.numberOfPointsForAnimation, date: lastUpdatedDate)
//            lastCoordinatesForAnnotation[$0.id] = $0.locationTimeSeries?.coordinates.last?.location
//            return slice
//        })
//        data.forEach({
//            lastCoordinatesForAnnotation[$0.id] = $0.locationTimeSeries?.coordinates.last?.location
//        })
//        lastUpdatedDate = Date()
        data.forEach { (annotationData) in
            if annotationData.isCurrentUser {
                if let view = mapView.view(for: mapView.userLocation) as? HTAnnotationView {
                    view.data = annotationData
                }
            } else {
                var annotation: HTAnnotation? = annotationMap[annotationData.id]
                if annotation == nil {
                    annotation = HTAnnotation(data: annotationData)
                    mapView.addAnnotation(annotation!)
                    annotationMap[annotationData.id] = annotation!
                } else {
                    annotation?.update(annotationData)
                }
                if annotationData.metaData.type == .destination {
                    annotation?.coordinate = annotationData.coordinate
                } else {
                    if annotationData.coordinate.latitude != annotation?.coordinate.latitude && annotationData.coordinate.longitude != annotation?.coordinate.longitude {
                        animateMarker(annotation: annotation, location: annotationData.coordinate)
                    }
                }
                if let view = mapView.view(for: annotation!) as? HTAnnotationView {
                    view.data = annotationData
                }
            }
        }
        centerMapOnAllAnnotationsInternal(true)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.addTrailingPolyline(trailingPolylineData)
//        }
    }
    
    fileprivate func animateMarker(annotation: HTAnnotation?, location: CLLocationCoordinate2D) {
        guard let annotation = annotation else { return }
        let rotationDuration: Double = 0.5
        let movementDuration: Double = 1
        let bearing = HTMapUtils.headingFrom(annotation.coordinate, next: location)
        print(bearing)
        print(location)
        DispatchQueue.main.async {
            if let view = self.mapView.view(for: annotation) as? HTAnnotationView {
                UIView.animate(withDuration: rotationDuration, delay: 0, options: .curveEaseOut, animations: {
                    view.rotateForBearing(CGFloat(bearing * Double.pi / 180.0))
                }, completion: nil)
            }
            UIView.animate(withDuration: movementDuration, delay: 0, options: .curveEaseOut, animations: {
                annotation.coordinate = location
            }, completion: nil)
        }
    }
    
    public func addPolyline(_ data: [HTPolylineData]) {
        mapView.removeOverlays(mapView.overlays)
        data.forEach({
            addSinglePolyline($0)
        })
    }
    
    public func showCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
        mapView.showAnnotations(
            coordinates.map({ (coordinate) in
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            return annotation
        }), animated: true)
    }
    
    fileprivate func addSinglePolyline(_ data: HTPolylineData) {
        let polyline = HTPolyline(data: data)
        mapView.add(polyline)
    }
    
    fileprivate func animateMarker(_ annotation: HTAnnotation, coordinates: [TimedCoordinates], index: Int = 0, total: Double = 0, lastUpdatedDate: Date) {
        guard index < coordinates.count else {
            return
        }
        let totalMovementDuration: Double = 5
        let rotationDuration: Double = (totalMovementDuration/Double(HTProvider.numberOfPointsForAnimation))
        let movementDuration: Double = rotationDuration//(totalMovementDuration/Double(coordinates.count * 2 + 1 - index))
        let timedCoordinate = coordinates[index]
        if let view = self.mapView.view(for: annotation) as? HTAnnotationView {
            UIView.animate(withDuration: rotationDuration, delay: 0, options: .curveEaseOut, animations: {
                view.rotateForBearing(CGFloat(timedCoordinate.bearing * Double.pi / 180.0))
            }, completion: nil)
        }
        UIView.animate(withDuration: movementDuration, delay: 0, options: .curveEaseOut, animations: {
            annotation.coordinate = timedCoordinate.location
        }, completion: { (_) in
            self.animateMarker(annotation, coordinates: coordinates, index: index+1, total: total + movementDuration, lastUpdatedDate: lastUpdatedDate)
        })
    }
    
    public func addTrailingPolyline(_ data: [HTTimeAwarePolyline]) {
        data.forEach({
            if let annotation = annotationMap[$0.id] {
                animateMarker(annotation, coordinates: $0.coordinates, lastUpdatedDate: lastUpdatedDate)
            }
        })
        lastUpdatedDate = Date()
    }
    
    public func updateMapVisibleRegion(_ insets: UIEdgeInsets) {
        mapView.layoutMargins = insets
        debouncedOperation?.call()
    }
    
    public func getCenterCoordinates() -> CLLocationCoordinate2D {
        return mapView.centerCoordinate
    }
}

/// Apple Maps components
final class HTAnnotation: MKPointAnnotation {
    private (set) var data: HTAnnotationData?
    
    func update(_ data: HTAnnotationData) {
//        self.coordinate = data.coordinate
        self.data = data
    }
    
    init(data: HTAnnotationData) {
        super.init()
        self.coordinate = data.coordinate
        self.data = data
    }
}

final class HTPolyline: MKPolyline {
    var data: HTPolylineData?
    
    convenience init(data: HTPolylineData) {
        self.init(coordinates: data.coordinates, count: data.coordinates.count)
        self.data = data
    }
    
}

//final class HTDottedPolylineRenderer: MKPolylineRenderer {
//    override func applyStrokeProperties(to context: CGContext, atZoomScale zoomScale: MKZoomScale) {
//        super.applyStrokeProperties(to: context, atZoomScale: zoomScale)
//
//        if let ctx = UIGraphicsGetCurrentContext() {
//            ctx.setLineWidth(self.lineWidth)
//            ctx.setLineCap(self.lineCap)
//        }
//    }
//}

