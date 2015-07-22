//
//  ActivityIndicatorButton.swift
//  JPC.ActivityIndicatorButton
//
//  Created by Jon Chmura on 3/9/15 (Happy Apple Watch Day!).
//  Copyright (c) 2015 Jon Chmura. All rights reserved.
//
/*

The MIT License (MIT)

Copyright (c) 2015 jpchmura

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.



*/

import UIKit



private extension CGRect {
    
    var center: CGPoint {
        get {
            return CGPoint(x: self.midX, y: self.midY)
        }
    }
    
}




public enum ActivityIndicatorButtonStyle {
    case Outline, Solid
}

public enum ActivityIndicatorButtonAnimationStyle {
    case Fade, Expand
}

public enum ActivityIndicatorButtonProgressBarStyle: Equatable {
    case Inactive, Spinning, Percentage(value: Float)
}

public struct ActivityIndicatorButtonState: Equatable {
    
    public var tintColor: UIColor
    public var trackColor: UIColor
    public var image: UIImage?
    public var progressBarStyle: ActivityIndicatorButtonProgressBarStyle
    
    public init(tintColor: UIColor, trackColor: UIColor, image: UIImage?, progressBarStyle: ActivityIndicatorButtonProgressBarStyle) {
        self.tintColor = tintColor
        self.trackColor = trackColor
        self.image = image
        self.progressBarStyle = progressBarStyle
    }
}

public func == (lhs: ActivityIndicatorButtonProgressBarStyle, rhs: ActivityIndicatorButtonProgressBarStyle) -> Bool {
    switch lhs {
    case .Inactive:
        switch rhs {
        case .Inactive:
            return true
        default:
            return false
        }
        
    case .Spinning:
        switch rhs {
        case .Spinning:
            return true
        default:
            return false
        }
        
    case .Percentage(let lhsValue):
        switch rhs {
        case .Percentage(let rhsValue):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}

public func == (lhs: ActivityIndicatorButtonState, rhs: ActivityIndicatorButtonState) -> Bool {
    return lhs.tintColor == rhs.tintColor && lhs.trackColor == rhs.trackColor && lhs.image == rhs.image && lhs.progressBarStyle == rhs.progressBarStyle
}




@IBDesignable
public class ActivityIndicatorButton: UIControl {


    
    
    
    
    // MARK: - Public API
    
    
    
    // MARK: State
    
    public var _activityState: ActivityIndicatorButtonState = ActivityIndicatorButtonState(tintColor: UIColor.blueColor(), trackColor: UIColor.lightGrayColor(), image: nil, progressBarStyle: .Inactive)
    
    public var activityState: ActivityIndicatorButtonState {
        get {
            return _activityState
        }
        set {
            _activityState = newValue
            self.updateForNextActivityState(animated: true)
        }
    }
    
    
    public func transitionActivityState(toState: ActivityIndicatorButtonState, animated: Bool = true) {
        self._activityState = toState
        self.updateForNextActivityState(animated: animated)
    }
    
    
    
    // MARK: State Animations
    
    /// Defines the length of the animation for ActivityState transitions.
    public var animationDuration: CFTimeInterval = 0.2
    
    /// The timing function for ActivityState transitions.
    public var animationTimingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
    
    
    
    
    // MARK: Hit Ripple Animation
    
    /// The distance past the edge of the button which the ripple animation will propagate on touch up and touch down
    @IBInspectable public var hitAnimationDistance: CGFloat = 5.0
    
    /// The duration of the ripple hit animation
    @IBInspectable public var hitAnimationDuration: CFTimeInterval = 0.5
    
    /// The color of the touch down and touch up ripple animation. Default value is UIColor.grayColor().colorWithAlphaComponent(0.25).
    @IBInspectable public var hitAnimationColor: UIColor = UIColor.grayColor().colorWithAlphaComponent(0.5)
    
    
    
    // MARK: Style
    
    /// The color of the drop shadow or UIColor.clearColor() if you do not wish to display a shadow. The shadow never drawn is useSolidColorButtons is false.
    /// :see: useSolidColorButtons
    @IBInspectable public var shadowColor: UIColor = UIColor.blackColor()
    
    
    /// If true the circular background of this control is colored with the tint color and the image is colored white. Otherwise the background is clear and the image is tinted. Image color is only adjusted if it is a template image.
    @IBInspectable public var style: ActivityIndicatorButtonStyle = .Solid {
        didSet {
            self.updateAllColors()
        }
    }
    
    @IBInspectable public var animationStyle: ActivityIndicatorButtonAnimationStyle = .Expand
    
    
    
    
    
    // MARK: - Initialization
    
    public init() {
        super.init(frame: CGRectZero)
        commonInit()
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        initialLayoutSetup()
        updateAllColors()
        updateForNextActivityState(animated: false)
        
        // Observe touch down and up for fire ripple animations
        self.addTarget(self, action: "handleTouchUp:", forControlEvents: .TouchUpInside)
        self.addTarget(self, action: "handleTouchDown:", forControlEvents: .TouchDown)
    }
    
    
    
    
    struct Constants {
        struct Layout {
            static let outerPadding: CGFloat = 1
            static let progressWidth: CGFloat = 2.5
            static let trackWidth: CGFloat = 1
            /// The intrinsicContentSize if no images are provided. If images are provided this is the intrinsicContentSize.
            static let defaultContentSize: CGSize = CGSizeMake(35.0, 35.0)
            /// For intrinsicContentSize calculations this is the padding between the image and the background.
            static let minimumImagePadding: CGFloat = 5
        }
        struct Track {
            static let StartAngle = CGFloat(-M_PI_2)  // Start angle is pointing directly upwards on the screen. This is where progress animations will begin
            static let EndAngle = CGFloat(3 * M_PI_2)
        }
    }
    


    // MARK: - IBDesignable

    public override func prepareForInterfaceBuilder() {
        // TODO: Improve rendering for interface builder preview
    }



    
    
    // MARK: - State Animations
    
    
    /// Holds the currently rendered State
    private var currentActivityState: ActivityIndicatorButtonState?
    
    /**
    Does the real work of transitioning from one ActivityState to the next. If previous state is set will also update out of that state.
    */
    private func updateForNextActivityState(#animated: Bool) {

        struct DisplayState {
            let trackVisible: Bool
            let progressBarVisible: Bool
            let tintColor: UIColor
            let trackColor: UIColor
            let image: UIImage?
            let progressBarStyle: ActivityIndicatorButtonProgressBarStyle
            
            init(state: ActivityIndicatorButtonState, style: ActivityIndicatorButtonStyle) {
                self.trackVisible = style == .Solid || state.progressBarStyle != .Spinning
                self.progressBarVisible = state.progressBarStyle != .Inactive
                self.tintColor = state.tintColor
                self.trackColor = state.trackColor
                self.image = state.image
                self.progressBarStyle = state.progressBarStyle
            }
            
            init(currentViewState: ActivityIndicatorButton) {
                self.trackVisible = currentViewState.backgroundView.shapeLayer.opacity > 0.5
                self.progressBarVisible = currentViewState.progressView.progressLayer.opacity > 0.5
                self.tintColor = UIColor(CGColor: currentViewState.style == .Solid ? currentViewState.backgroundView.shapeLayer.fillColor : currentViewState.backgroundView.shapeLayer.strokeColor)!
                self.trackColor = UIColor(CGColor: currentViewState.backgroundView.shapeLayer.strokeColor)!
                self.image = currentViewState.imageView.image
                self.progressBarStyle = currentViewState.currentActivityState != nil ? currentViewState.currentActivityState!.progressBarStyle : .Inactive
            }
        }


        var nextDisplayState = DisplayState(state: activityState, style: self.style)
        var prevDisplayState = DisplayState(currentViewState: self)


        
        // Progress View and Background View animations

        struct OpacityAnimation {
            let toValue: Float
            let fromValue: Float

            init(hidden: Bool) {
                self.toValue = hidden ? 0.0 : 1.0
                self.fromValue = hidden ? 1.0 : 0.0
            }

            func addToLayer(layer: CALayer, duration: CFTimeInterval, function: CAMediaTimingFunction) {
                let opacityanim = CABasicAnimation(keyPath: "opacity")
                opacityanim.toValue = self.toValue
                opacityanim.fromValue = self.fromValue
                opacityanim.duration = duration
                opacityanim.timingFunction = function
                layer.addAnimation(opacityanim, forKey: "opacity")

                layer.opacity = toValue
            }

            func setNoAnimation(layer: CALayer) {
                CATransaction.begin()
                CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                layer.opacity = toValue
                CATransaction.commit()
            }
        }

        var trackOpacity = OpacityAnimation(hidden: !nextDisplayState.trackVisible)
        var progressOpacity = OpacityAnimation(hidden: !nextDisplayState.progressBarVisible)

        // Only animate if value has changed
        let shouldAnimateTrack = animated && prevDisplayState.trackVisible != nextDisplayState.trackVisible
        let shouldAnimateProgressBar = animated && prevDisplayState.progressBarVisible != prevDisplayState.progressBarVisible
        let shouldAnimateImage = animated && prevDisplayState.image != nextDisplayState.image

        if shouldAnimateTrack {
            trackOpacity.addToLayer(self.backgroundView.shapeLayer, duration: self.animationDuration, function: self.animationTimingFunction)
        }
        else {
            trackOpacity.setNoAnimation(self.backgroundView.shapeLayer)
        }

        if shouldAnimateProgressBar {
            progressOpacity.addToLayer(self.progressView.progressLayer, duration: self.animationDuration, function: self.animationTimingFunction)
        }
        else {
            progressOpacity.setNoAnimation(self.progressView.progressLayer)
        }

        
        
        // A helper to get a "compressed" path represented by a single point at the center of the existing path.
        func compressPath(path: CGPath) -> CGPath {
            let bounds = CGPathGetPathBoundingBox(path)
            let center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
            return UIBezierPath(arcCenter: center, radius: 0.0, startAngle: 0.0, endAngle: CGFloat(M_PI * 2), clockwise: true).CGPath
        }

        
        
        // Color transition for "useSolidColorButtons"
        // If the tint color is different between 2 states we animate the change by expanding the new color from the center of the button
        if prevDisplayState.tintColor != nextDisplayState.tintColor && self.style == .Solid  {
            
            // The transition layer provides the expanding color change in the state transition. The background view color isn't updating until completing this expand animation
            let transitionLayer = CAShapeLayer()
            transitionLayer.path = self.backgroundLayerPath
            
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            transitionLayer.fillColor = nextDisplayState.tintColor.CGColor
            CATransaction.commit()
            
            self.backgroundView.layer.addSublayer(transitionLayer)
         
            let completion = { () -> Void in
                
                transitionLayer.removeFromSuperlayer()
                self.updateAllColors()
            }
            
            CATransaction.begin()
            CATransaction.setCompletionBlock(completion)
            
            let bgAnim = CABasicAnimation(keyPath: "path")
            bgAnim.fromValue = compressPath(self.backgroundLayerPath)
            bgAnim.toValue = self.backgroundLayerPath
            bgAnim.duration = self.animationDuration
            bgAnim.timingFunction = self.animationTimingFunction
            
            transitionLayer.addAnimation(bgAnim, forKey: "bg_expand")
            
            CATransaction.commit()
        }
        else {
            self.updateAllColors()
        }
        
        
        

        // Update the image before we drive the animations
        self.setImage(nextDisplayState.image)

        // If image has changed and we're animating...
        // For image animations we reveal the new image from the center by expanding its mask
        if shouldAnimateImage {
            
            // Image mask expand
            let imageAnim = CABasicAnimation(keyPath: "path")
            imageAnim.fromValue = compressPath(self.imageViewMaskPath)
            imageAnim.toValue = self.imageViewMaskPath
            imageAnim.duration = self.animationDuration
            imageAnim.timingFunction = self.animationTimingFunction
            
            self.imageViewMask.addAnimation(imageAnim, forKey: "image_expand")
        }
        else {
            updateAllColors()
        }

        
        // Restart / adjust progress view if needed
        self.updateSpinningAnimation()
        
        switch prevDisplayState.progressBarStyle {
        case .Percentage(let value):
            self.updateProgress(fromValue: value, animated: animated)
            
        default:
            self.updateProgress(fromValue: 0, animated: animated)
        }
        
        
        // Finally update our current activity state
        self.currentActivityState = activityState
    }


    
    private func updateProgress(fromValue prevValue: Float, animated: Bool) {
        switch self.activityState.progressBarStyle {
        case .Percentage(let value):
            
            if animated {
                let anim = CABasicAnimation(keyPath: "strokeEnd")
                anim.fromValue = prevValue
                anim.toValue = value
                anim.duration = self.animationDuration
                anim.timingFunction = self.animationTimingFunction
                self.progressView.progressLayer.addAnimation(anim, forKey: "progress")
                
                self.progressView.progressLayer.strokeEnd = CGFloat(value)
            }
            else {
                CATransaction.begin()
                CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                self.progressView.progressLayer.strokeEnd = CGFloat(value)
                CATransaction.commit()
            }
            
        default:
            break
        }
    }

    
    /// This replicates the Google style activity spinner from Material Design
    private func updateSpinningAnimation() {

        let kStrokeAnim = "spinning_stroke"
        let kRotationAnim = "spinning_rotation"

        self.progressView.progressLayer.removeAnimationForKey(kStrokeAnim)
        self.progressView.progressLayer.removeAnimationForKey(kRotationAnim)
        if self.activityState.progressBarStyle == .Spinning {

            // The animation is broken into stages that execute in order. All animations in "stage 1" execute simultaneously followed by animations in "stage 2"
            // "Head" refers to the strokeStart which is trailing behind the animation (i.e. the animation is moving clockwise away from the head)
            // "Tail refers to the strokeEnd which is leading the animation
            
            let stage1Time = 0.9
            let pause1Time = 0.05
            let stage2Time = 0.6
            let pause2Time = 0.05
            let stage3Time = 0.1

            var animationTime = stage1Time

            // Stage1: The circle begins life empty, nothing is stroked.  The tail moves ahead to travel the circumference of the circle. The head follows but lags behind 75% of the circumference. Now 75% of the circles circumference is stroked.
            
            let headStage1 = CABasicAnimation(keyPath: "strokeStart")
            headStage1.fromValue = 0.0
            headStage1.toValue = 0.25
            headStage1.duration = animationTime

            let tailStage1 = CABasicAnimation(keyPath: "strokeEnd")
            tailStage1.fromValue = 0.0
            tailStage1.toValue = 1.0
            tailStage1.duration = animationTime

            // Pause1: Maintain state from stage 1 for a moment

            let headPause1 = CABasicAnimation(keyPath: "strokeStart")
            headPause1.fromValue = 0.25
            headPause1.toValue = 0.25
            headPause1.beginTime = animationTime
            headPause1.duration = pause1Time

            let tailPause1 = CABasicAnimation(keyPath: "strokeEnd")
            tailPause1.fromValue = 1.0
            tailPause1.toValue = 1.0
            tailPause1.beginTime = animationTime
            tailPause1.duration = pause1Time

            animationTime += pause1Time
            
            // Stage2: The head whips around the circle to almost catch up with the tail. The tail stays at the end of the circle. Now 10% of the circles circumference is stroked.

            let headStage2 = CABasicAnimation(keyPath: "strokeStart")
            headStage2.fromValue = 0.25
            headStage2.toValue = 0.9
            headStage2.beginTime = animationTime
            headStage2.duration = stage2Time

            let tailStage2 = CABasicAnimation(keyPath: "strokeEnd")
            tailStage2.fromValue = 1.0
            tailStage2.toValue = 1.0
            tailStage2.beginTime = animationTime
            tailStage2.duration = stage2Time

            animationTime += stage2Time
            
            // Pause2: Maintain state from Stage2 for a moment.

            let headPause2 = CABasicAnimation(keyPath: "strokeStart")
            headPause2.fromValue = 0.9
            headPause2.toValue = 0.9
            headPause2.beginTime = animationTime
            headPause2.duration = pause2Time

            let tailPause2 = CABasicAnimation(keyPath: "strokeEnd")
            tailPause2.fromValue = 1.0
            tailPause2.toValue = 1.0
            tailPause2.beginTime = animationTime
            tailPause2.duration = pause2Time

            animationTime += pause2Time
            
            // Stage3: The head moves to 100% the circumference to finally catch up with the tail which remains stationary. Now none of the circle is stroked and we are back at the starting state.

            let headStage3 = CABasicAnimation(keyPath: "strokeStart")
            headStage3.fromValue = 0.9
            headStage3.toValue = 1.0
            headStage3.beginTime = animationTime
            headStage3.duration = stage3Time

            let tailStage3 = CABasicAnimation(keyPath: "strokeEnd")
            tailStage3.fromValue = 1.0
            tailStage3.toValue = 1.0
            tailStage3.beginTime = animationTime
            tailStage3.duration = stage3Time

            animationTime += stage3Time

            let group = CAAnimationGroup()
            group.repeatCount = Float.infinity
            group.duration = animationTime
            group.animations = [headStage1, tailStage1, headPause1, tailPause1, headStage2, tailStage2, headPause2, tailPause2, headStage3, tailStage3]

            self.progressView.progressLayer.addAnimation(group, forKey: kStrokeAnim)

            let rotationAnim = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnim.fromValue = 0
            rotationAnim.toValue = 2 * M_PI
            rotationAnim.duration = 3.0
            rotationAnim.repeatCount = Float.infinity

            self.progressView.progressLayer.addAnimation(rotationAnim, forKey: kRotationAnim)
        }
    }
    
    
    // MARK: - Theming
    
    override public func tintColorDidChange() {
        super.tintColorDidChange()
        
        updateAllColors()
    }
    
    private func updateButtonColors() {
        let tintColor = self.activityState.tintColor
        
        switch self.style {
        case .Outline:
            self.backgroundView.shapeLayer.fillColor = UIColor.clearColor().CGColor
            self.imageView.tintColor = tintColor
            self.dropShadowLayer.shadowColor = UIColor.clearColor().CGColor
            
        case .Solid:
            self.backgroundView.shapeLayer.fillColor = tintColor.CGColor
            self.imageView.tintColor = UIColor.whiteColor()
            self.dropShadowLayer.shadowColor = self.shadowColor.CGColor
        }
    }
    
    private func updateTrackColors() {
        let tintColor = self.activityState.tintColor.CGColor
        let trackColor = self.activityState.trackColor.CGColor
        let clear = UIColor.clearColor().CGColor
        
        self.progressView.progressLayer.strokeColor = tintColor
        self.progressView.progressLayer.fillColor = clear
        self.progressView.progressLayer.lineWidth = Constants.Layout.progressWidth
        
        self.backgroundView.shapeLayer.strokeColor = trackColor
        self.backgroundView.shapeLayer.lineWidth = Constants.Layout.trackWidth
    }
    
    private func updateAllColors() {
        self.updateButtonColors()
        self.updateTrackColors()
    }





    




    // MARK: - UI (Private)
    
    /*

    We are wrapping all our layers in views for easier arrangment.

    */
    
    private class BackgroundView: UIView {
        
        var shapeLayer: CAShapeLayer {
            get {
                return self.layer as! CAShapeLayer
            }
        }
        
        override class func layerClass() -> AnyClass {
            return CAShapeLayer.self
        }
        
    }
    
    private class ProgressView: UIView {

        var progressLayer: CAShapeLayer {
            get {
                return self.layer as! CAShapeLayer
            }
        }
        
        override class func layerClass() -> AnyClass {
            return CAShapeLayer.self
        }
        
    }
    
    /// The layer from which to draw the button shadow
    private var dropShadowLayer: CALayer {
        get {
            return self.layer
        }
    }

    private lazy var imageView: UIImageView = UIImageView()
    
    private lazy var imageViewMask: CAShapeLayer = CAShapeLayer()
    
    private lazy var backgroundView: BackgroundView = BackgroundView()
    
    private lazy var progressView: ProgressView = ProgressView()


    private func setImage(image: UIImage?) {
        self.imageView.image = image
        self.imageView.sizeToFit()
    }







    // MARK: - Layout
    
    private var progressLayerPath: CGPath {
        get {
            let progressRadius = min(self.progressView.frame.width, self.progressView.frame.height) * 0.5
            return UIBezierPath(
                arcCenter: self.progressView.bounds.center,
                radius: progressRadius - Constants.Layout.progressWidth * 0.5,
                startAngle: Constants.Track.StartAngle,
                endAngle: Constants.Track.EndAngle,
                clockwise: true).CGPath
        }
    }

    private var backgroundLayerPathRadius: CGFloat {
        get {
            return min(self.backgroundView.frame.width, self.backgroundView.frame.height) * 0.5
        }
    }
    
    private var backgroundLayerPath: CGPath {
        get {
            return UIBezierPath(arcCenter: self.backgroundView.bounds.center, radius: self.backgroundLayerPathRadius, startAngle: Constants.Track.StartAngle, endAngle: Constants.Track.EndAngle, clockwise: true).CGPath
        }
    }
    
    private var imageViewMaskPath: CGPath {
        get {
            return UIBezierPath(arcCenter: self.imageView.bounds.center, radius: self.backgroundLayerPathRadius, startAngle: Constants.Track.StartAngle, endAngle: Constants.Track.EndAngle, clockwise: true).CGPath
        }
    }
    
    private var shadowPath: CGPath {
        get {
            return UIBezierPath(arcCenter: self.bounds.center, radius: self.backgroundLayerPathRadius, startAngle: Constants.Track.StartAngle, endAngle: Constants.Track.EndAngle, clockwise: true).CGPath
        }
    }
    

    /**
    Should be called once and only once. Adds layers to view heirarchy.
    */
    private func initialLayoutSetup() {

        self.imageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.backgroundView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.progressView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        self.imageView.backgroundColor = UIColor.clearColor()
        self.backgroundView.backgroundColor = UIColor.clearColor()
        self.progressView.backgroundColor = UIColor.clearColor()
        
        self.imageView.userInteractionEnabled = false
        self.backgroundView.userInteractionEnabled = false
        self.progressView.userInteractionEnabled = false
        
        self.backgroundColor = UIColor.clearColor()
        
        self.addSubview(self.backgroundView)
        self.addSubview(self.imageView)
        self.addSubview(self.progressView)

        let views = ["bg" : self.backgroundView, "progress" : self.progressView]
        let metrics: [String : NSNumber] = ["OUTER" : Constants.Layout.outerPadding, "INNER" : Constants.Layout.outerPadding + Constants.Layout.progressWidth + 0.5 * Constants.Layout.trackWidth] // The "INNER" padding is the distance between the bounds and the track. Have to add the width of the progress and the half of the track (the track is the stroke of the background view)
        
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(OUTER)-[progress]-(OUTER)-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(OUTER)-[progress]-(OUTER)-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))

        self.addConstraint(NSLayoutConstraint(item: self.imageView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
        self.addConstraint(NSLayoutConstraint(item: self.imageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0))

        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(INNER)-[bg]-(INNER)-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(INNER)-[bg]-(INNER)-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
        
        // Set up imageViewMask
        
        self.imageViewMask.fillColor = UIColor.whiteColor().CGColor
        self.imageView.layer.mask = self.imageViewMask
        
        // Set up drop shadow
        let layer = self.dropShadowLayer
        layer.shadowOffset = CGSizeMake(0, 2)
        layer.shadowRadius = 2.5
        layer.shadowOpacity = 0.5
        layer.masksToBounds = false
    }


    /**
    Should be called when bounds change to update paths of shape layers.
    */
    private func updateForCurrentBounds() {

        self.progressView.progressLayer.path = self.progressLayerPath
        self.backgroundView.shapeLayer.path = self.backgroundLayerPath
        self.imageViewMask.path = self.imageViewMaskPath
        self.dropShadowLayer.shadowPath = self.shadowPath
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        updateForCurrentBounds()
    }

    public override func intrinsicContentSize() -> CGSize {
        var maxW: CGFloat = Constants.Layout.defaultContentSize.width
        var maxH: CGFloat = Constants.Layout.defaultContentSize.height

        let padding = 2 * (Constants.Layout.minimumImagePadding + Constants.Layout.trackWidth + Constants.Layout.progressWidth + Constants.Layout.outerPadding)

        if let imageSize = self.activityState.image?.size {
            maxW = max(imageSize.width, maxW) + padding
            maxH = max(imageSize.height, maxH) + padding
        }

        return CGSizeMake(maxW, maxH)
    }






    // MARK: - Hit Animation

    func handleTouchUp(sender: ActivityIndicatorButton) {

        self.createRippleHitAnimation(true)
    }

    func handleTouchDown(sender: ActivityIndicatorButton) {

        self.createRippleHitAnimation(false)
    }


    /**
    Creates a new layer under the control which expands outward.
    */
    private func createRippleHitAnimation(isTouchUp: Bool) {

        let duration = self.hitAnimationDuration
        let distance: CGFloat = self.hitAnimationDistance
        let color = self.hitAnimationColor.CGColor
        let timing = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)

        let layer = CAShapeLayer()
        layer.fillColor = color
        layer.strokeColor = UIColor.clearColor().CGColor
        self.layer.insertSublayer(layer, atIndex: 0)

        let bounds = self.bounds
        let radius = max(bounds.width, bounds.height) * 0.5
        let center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
        let fromPath = UIBezierPath(arcCenter: center, radius: 0.0, startAngle: 0.0, endAngle: CGFloat(2 * M_PI), clockwise: true).CGPath
        let toPath = UIBezierPath(arcCenter: center, radius: radius + distance, startAngle: 0.0, endAngle: CGFloat(2 * M_PI), clockwise: true).CGPath

        let completion = { () -> Void in
            layer.removeFromSuperlayer()
        }

        func scaleLayer(layer: CALayer, offset: CGFloat) {

            var scaleFromValue = CATransform3DIdentity
            var scaleToValue = CATransform3DMakeScale(0.98 - offset, 0.98 - offset, 1.0)

            if isTouchUp {
                swap(&scaleFromValue, &scaleToValue)
            }

            let scaleAnim = CABasicAnimation(keyPath: "transform")
            scaleAnim.fromValue = NSValue(CATransform3D: scaleFromValue)
            scaleAnim.toValue = NSValue(CATransform3D: scaleToValue)
            scaleAnim.duration = duration
            scaleAnim.timingFunction = timing

            layer.addAnimation(scaleAnim, forKey: "hit_scale")
            layer.transform = scaleToValue
        }

        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)

        let pathAnim = CABasicAnimation(keyPath: "path")
        pathAnim.fromValue = fromPath
        pathAnim.toValue = toPath

        let fadeAnim = CABasicAnimation(keyPath: "opacity")
        fadeAnim.fromValue = 1.0
        fadeAnim.toValue = 0.0

        scaleLayer(self.backgroundView.layer, 0.0)
        scaleLayer(self.dropShadowLayer, 0.0)

        let group = CAAnimationGroup()
        group.animations = [pathAnim, fadeAnim]
        group.duration = duration
        group.timingFunction = timing

        layer.addAnimation(group, forKey: "ripple")

        CATransaction.commit()
    }
    
}
