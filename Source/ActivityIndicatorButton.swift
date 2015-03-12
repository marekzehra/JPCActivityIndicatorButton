//
//  ActivityIndicatorButton.swift
//  JPC.ActivityIndicatorButton
//
//  Created by Jon Chmura on 3/9/15 (Happy Apple Watch Day!).
//  Copyright (c) 2015 Jon Chmura. All rights reserved.
//

import UIKit

@IBDesignable
public class ActivityIndicatorButton: UIControl {

    
    /**
    The Style of the activity button. This defines the "state" of the activity indicator. Use UIControlState for the state of the button.
    
    - Inactive: Inactive image with circular outline.
    - Spinning: Spinning image surrounded by animated spinning line. Circular outline not displayed.
    - Progress: Progress image surrouded by ciruclar progress bar.
    - Paused:   Paused image. Progress bar or spinning indicator suspended in action.
    - Complete: Complete image with circular outline.
    */
    public enum ActivityState {
        case Inactive, Spinning, Progress, Paused, Complete
        
        static func allValues() -> [ActivityState] {
            return [Inactive, Spinning, Progress, Paused, Complete]
        }
    }
    
    
    
    
    // MARK: - IBDesignable
    
    public override func prepareForInterfaceBuilder() {
        // TODO: Render for interface builder preview
    }
    
    
    
    
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
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
        updateForCurrentStyle(previousState: nil, animated: false)
    }
    
    
    
    
    
    // MARK: - Configuration
    
    public let animationDuration: CFTimeInterval = 0.2
    
    private var _activityState: ActivityState = .Inactive
    
    /// Transition the control to a Style. Equivalent to calling transition(toStyle: animated:false)
    /// :see: transition(toStyle:animated:)
    public var activityState: ActivityState {
        get {
            return _activityState
        }
        set {
            transition(toActivityState: newValue, animated: false)
        }
    }
    
    /**
    Transition from current style to a new style.
    
    :param: toStyle  The new style
    :param: animated Animate the transition
    
    :see: style
    */
    public func transition(toActivityState state: ActivityState, animated: Bool) {
        
        if state != _activityState {
            let prev = _activityState
            _activityState = state
            
            updateForCurrentStyle(previousState: prev, animated: animated)
        }
    }
    
    /**
    Does the real work of transitioning from one style to the next. If previous style is set will also update out of that style.
    */
    private func updateForCurrentStyle(previousState prevState: ActivityState?, animated: Bool) {
        
        
        func configForState(state: ActivityState) -> (showTrack: Bool, showProgress: Bool, image: UIImage?) {
            
            var showTrack = false
            var showProgress = false
            let image = self.image(forActivityState: state)
            
            switch state {
            case .Inactive:
                showTrack = true
                showProgress = false
            case .Spinning:
                showTrack = false
                showProgress = true
            case .Progress:
                showTrack = true
                showProgress = true
            case .Paused:
                break
            case .Complete:
                showTrack = true
                showProgress = false
            }
            
            return (showTrack, showProgress, image)
        }
        
        
        
        
        
        var nextValues = configForState(_activityState)
        var prevValues = prevState != nil ? configForState(prevState!) : (showTrack: !nextValues.showTrack, showProgress: !nextValues.showProgress, image: nil)
        
        // Edge case: Paused state never modifies values
        if _activityState == .Paused {
            nextValues.showTrack = prevValues.showTrack
            nextValues.showProgress = prevValues.showProgress
        }
        

        
        struct OpacityAnimation {
            let toValue: Float
            let fromValue: Float
            
            init(hidden: Bool) {
                self.toValue = hidden ? 0.0 : 1.0
                self.fromValue = hidden ? 1.0 : 0.0
            }
            
            func addToLayer(layer: CALayer, duration: CFTimeInterval) {
                let opacityanim = CABasicAnimation(keyPath: "opacity")
                opacityanim.toValue = self.toValue
                opacityanim.fromValue = self.fromValue
                opacityanim.duration = duration
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
        
        
        
        struct ScaleAnimation {
            var isExpand: Bool = false
            
            var completion: (() -> Void)?
            
            init() {
                
            }
            
            init(isExpand: Bool) {
                self.isExpand = isExpand
            }
            
            func addToLayer(layer: CAShapeLayer, shadowLayer: CALayer?, duration: CFTimeInterval){
                
                // Shadow path is identical to button mask - ***** Should this change update this code
                let currentPath = layer.path
                let bounds = CGPathGetPathBoundingBox(currentPath)
                let center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
                let compressed = UIBezierPath(arcCenter: center, radius: 0.0, startAngle: 0.0, endAngle: CGFloat(M_PI * 2), clockwise: true).CGPath
                
                let fromValue = isExpand ? compressed : currentPath
                let toValue = isExpand ? currentPath : compressed
                
                CATransaction.begin()
                
                if let handler = completion {
                    CATransaction.setCompletionBlock(handler)
                }
                let anim = CABasicAnimation(keyPath: "path")
                anim.fromValue = fromValue
                anim.toValue = toValue
                anim.duration = duration
                
                layer.addAnimation(anim, forKey: "path_scale")
                
                if let shadowLayer = shadowLayer {
                    
                    let anim = CABasicAnimation(keyPath: "shadowPath")
                    anim.fromValue = fromValue
                    anim.toValue = toValue
                    anim.duration = duration
                    
                    shadowLayer.addAnimation(anim, forKey: "shadowPath")
                }
                
                CATransaction.commit()
            }
            
        }
        
        
        
        
        var trackOpacity = OpacityAnimation(hidden: !nextValues.showTrack)
        var progressOpacity = OpacityAnimation(hidden: !nextValues.showProgress)
        
        let shouldAnimateTrack = animated && prevValues.showTrack != nextValues.showTrack
        let shouldAnimateProgressBar = animated && prevValues.showProgress != nextValues.showProgress
        let shouldAnimateImage = animated && prevValues.image != nextValues.image
        
        
        
        if shouldAnimateTrack {
            
            // Expand
            if nextValues.showTrack && prevValues.image == nil {
                
                trackOpacity.setNoAnimation(self.trackLayer)
                ScaleAnimation(isExpand: true).addToLayer(self.trackLayer, shadowLayer: nil, duration: self.animationDuration)
            }
            // Collapse
            else if !nextValues.showTrack && nextValues.image == nil {
                
                trackOpacity.setNoAnimation(self.trackLayer)
                ScaleAnimation(isExpand: false).addToLayer(self.trackLayer, shadowLayer: nil, duration: self.animationDuration)
            }
            // Fade track
            else {
                trackOpacity.addToLayer(self.trackLayer, duration: self.animationDuration)
            }
        }
        else {
            trackOpacity.setNoAnimation(self.trackLayer)
        }
        
        if shouldAnimateProgressBar {
            progressOpacity.addToLayer(self.progressLayer, duration: self.animationDuration)
        }
        else {
            progressOpacity.setNoAnimation(self.progressLayer)
        }
        
        
        
        let nextButtonView = self.centerButtonView
        self.centerButtonView.setImage(nextValues.image)
        
        
        // If image has changed and we're animating...
        if shouldAnimateImage {
            
            var anim = ScaleAnimation()
            
            // We only want to animate the drop shadow if the button is appearing or disapearing (i.e. one of the images is nil)
            let shadowLayer: CALayer? = (nextValues.image == nil) || (prevValues.image == nil) ? self.dropShadowLayer : nil
            
            // Collaspe old image
            if nextValues.image == nil {
                
                let completion = { () -> Void in
                    self.updateAllColors()
                }
                
                anim.isExpand = false
                anim.completion = completion
                anim.addToLayer(nextButtonView.mask, shadowLayer: shadowLayer, duration: self.animationDuration)
                
            }
            else {
                
                let tempBackgroundLayer = CAShapeLayer()
                tempBackgroundLayer.path = self.trackLayer.path
                
                self.updateButtonColors()
                
                // Add animation backing layer - We want the previous color to remain while the new button exands to fill its place. Add a backing layer to display the old color while we animate in the new one
                // FIXME: This layer is sized one pixel too big. Get the exact dimensions of the button
                if let prevState = prevState {
                    CATransaction.begin()
                    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                    tempBackgroundLayer.fillColor = (self.useSolidColorButtons && prevValues.image != nil ? self.tintColorForActivityState(prevState) : UIColor.clearColor()).CGColor
                    CATransaction.commit()
                    
                    self.layer.insertSublayer(tempBackgroundLayer, atIndex: 0)
                }
                
                let completion = { () -> Void in
                    tempBackgroundLayer.removeFromSuperlayer()
                    self.updateAllColors()
                }
                
                anim.isExpand = true
                anim.completion = completion
                anim.addToLayer(nextButtonView.mask, shadowLayer: shadowLayer, duration: self.animationDuration)
            }
            
        }
        else {
            updateAllColors()
        }
        
        self.updateSpinningAnimation()
        self.updateProgress(fromValue: 0.0, animated: animated)
    }
    
    private var _progress: Float = 0.0
    
    /// A float between 0.0 and 1.0 specifying the progress amount in the Progress state. This is displayed clockwise where 1.0 fills the whole circle. Equivalent to calling setProgress(animated: false).
    /// :see: setProgress(animated:)
    public var progress: Float {
        get {
            return _progress
        }
        set {
            setProgress(newValue, animated: false)
        }
    }
    
    /**
    Set the value of progress
    
    :param: progress The new progress value
    :param: animated Should animated the change
    
    :see: progress
    */
    public func setProgress(progress: Float, animated: Bool) {
        let prevValue = _progress
        _progress = progress
        
        updateProgress(fromValue: prevValue, animated: animated)
    }
    
    private func updateProgress(fromValue prevValue: Float, animated: Bool) {
        if activityState == .Progress {
            
            let anim = CABasicAnimation(keyPath: "strokeEnd")
            anim.fromValue = prevValue
            anim.toValue = _progress
            anim.duration = 0.2
            self.progressLayer.addAnimation(anim, forKey: "progress")
            
            self.progressLayer.strokeEnd = CGFloat(_progress)
        }
    }
    
    private func updateSpinningAnimation() {
        
        let kStrokeAnim = "spinning_stroke"
        let kRotationAnim = "spinning_rotation"
        
        self.progressLayer.removeAnimationForKey(kStrokeAnim)
        self.progressLayer.removeAnimationForKey(kRotationAnim)
        if activityState == .Spinning {
         
            
            // TODO: Clean this up
            let stage1Time = 0.9
            let pause1Time = 0.05
            let stage2Time = 0.6
            let pause2Time = 0.05
            let stage3Time = 0.1
            
            var animationTime = stage1Time
            
            let headStage1 = CABasicAnimation(keyPath: "strokeStart")
            headStage1.fromValue = 0.0
            headStage1.toValue = 0.25
            headStage1.duration = animationTime
            
            let tailStage1 = CABasicAnimation(keyPath: "strokeEnd")
            tailStage1.fromValue = 0.0
            tailStage1.toValue = 1.0
            tailStage1.duration = animationTime
            
            
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
            
            self.progressLayer.addAnimation(group, forKey: kStrokeAnim)
            
            let rotationAnim = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnim.fromValue = 0
            rotationAnim.toValue = 2 * M_PI
            rotationAnim.duration = 3.0
            rotationAnim.repeatCount = Float.infinity
            
            self.progressLayer.addAnimation(rotationAnim, forKey: kRotationAnim)
        }
    }
    
    
    
    
    // MARK: - Configuration
    
    
    // MARK: Colors
    
    
    /// The color of the drop shadow or UIColor.clearColor() if you do not wish to display a shadow. The shadow never drawn is useSolidColorButtons is false.
    /// :see: useSolidColorButtons
    @IBInspectable public var shadowColor: UIColor = UIColor.blackColor()
    
    
    /// The color of the touch down and touch up ripple animation. Default value is UIColor.grayColor().colorWithAlphaComponent(0.25).
    @IBInspectable public var hitAnimationColor: UIColor = UIColor.grayColor().colorWithAlphaComponent(0.25)
    
    
    /// If true the circular background of this control is colored with the tint color and the image is colored white. Otherwise the background is clear and the image is tinted. Image color is only adjusted if it is a template image.
    @IBInspectable public var useSolidColorButtons: Bool = false {
        didSet {
            self.updateAllColors()
        }
    }
    
    /// Data backing for setTintColor(forActivityState:)
    private var tintColorsByState = [ActivityState : UIColor]()
    
    /**
    Get the tint color used for an activity state. If a custom color is not set for the state the tint color of this control is returned
    
    :param: state The activity state
    
    :returns: The tint color for the activity state
    */
    public func tintColorForActivityState(state: ActivityState) -> UIColor {
        let color = self.tintColorsByState[state]
        return color == nil ? self.tintColor : color
    }
    
    /**
    Supercede the tintColor property of this control with another value for specific states
    
    :param: color  The tint color or nil to use the default tintColor property on this control
    :param: states A list of activity states
    */
    public func setTintColor(color: UIColor?, forActivityStates states: [ActivityState]) {
        for aState in states {
            if let color = color {
                self.tintColorsByState[aState] = color
            }
            else {
                self.tintColorsByState.removeValueForKey(aState)
            }
        }
    }
    
    
    private var trackColorByState = [ActivityState : UIColor]()
    
    /**
    Get the trackColor for an activity state
    
    :param: state The activity state
    
    :returns: The trackColor or the tintColor for that state is a trackColor doesn't not exist
    */
    public func trackColor(forActivityState state: ActivityState) -> UIColor {
        if let color = trackColorByState[state] {
            return color
        }
        return self.tintColorForActivityState(state)
    }
    
    /**
    Set a trackColor for activity states. If nil will use the tintColor for that state
    
    :param: color  The trackColor or nil to use the tintColor
    :param: states A list of states
    */
    public func setTrackColor(color: UIColor?, forActivityStates states: [ActivityState]) {
        for aState in states {
            if let color = color {
                self.trackColorByState[aState] = color
            }
            else {
                self.trackColorByState.removeValueForKey(aState)
            }
        }
    }
    
    
    
    
    // MARK: Images
    
    /// Data backing for setImage(forActivityState:)
    private var imagesByActivityState = [ActivityState : UIImage]()
    
    /**
    Set an image for a set of control states
    
    :param: image  The image for the control state or nil for no image
    :param: states An array of control states. Use ActivityState.allValues to apply the change for all
    */
    public func setImage(image: UIImage?, forActivityStates states: [ActivityState]) {
        for aState in states {
            if let image = image {
                imagesByActivityState[aState] = image
            }
            else {
                imagesByActivityState.removeValueForKey(aState)
            }
        }
        self.updateForCurrentStyle(previousState: nil, animated: false)
    }
    
    /**
    Get the image for an activity state
    
    :param: state The activity state
    
    :returns: The image that is used for the activity state or nil if no image
    */
    public func image(forActivityState state: ActivityState) -> UIImage? {
        return imagesByActivityState[state]
    }
    
    
    
    
    
    
    // MARK: - UI (Private)
    
    
    private class ButtonView {
    
        let containerView = UIView()
        var imageView = UIImageView()
        let mask = CAShapeLayer()
        
        init() {
            
            containerView.setTranslatesAutoresizingMaskIntoConstraints(false)
            imageView.setTranslatesAutoresizingMaskIntoConstraints(false)
            
            containerView.addSubview(imageView)
            containerView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .CenterX, relatedBy: .Equal, toItem: containerView, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
            containerView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .CenterY, relatedBy: .Equal, toItem: containerView, attribute: .CenterY, multiplier: 1.0, constant: 0.0))
            
            mask.fillColor = UIColor.whiteColor().CGColor
            containerView.layer.mask = mask
            
            imageView.userInteractionEnabled = false
            containerView.userInteractionEnabled = false
        }
        
        func setImage(image: UIImage?) {
            self.imageView.image = image
            self.imageView.sizeToFit()
        }
        
    }
    
    private var dropShadowLayer: CALayer {
        get {
            return self.layer
        }
    }
    
    /// Used to display the image
    private lazy var centerButtonView = ButtonView()
    
    /// View containing the layers. Makes it easier to keep the layers in the right zOrder.
    private lazy var activityContainerView: UIView = {
        let view = UIView()
        view.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.backgroundColor = UIColor.clearColor()
        view.userInteractionEnabled = false
        return view
    }()
    
    /// The spinning activity indicator
    private lazy var progressLayer: CAShapeLayer = CAShapeLayer()
    
    /// The outline around the progressLayer when state is Normal or Progress
    private lazy var trackLayer: CAShapeLayer = CAShapeLayer()
    
    
    
    
    
    
    // MARK: - Theming
    
    override public func tintColorDidChange() {
        super.tintColorDidChange()
        
        updateAllColors()
    }
    
    private func updateButtonColors() {
        let color = self.tintColorForActivityState(self.activityState)
        let tintColor = self.centerButtonView.imageView.image == nil ? UIColor.clearColor() : color
        
        if self.useSolidColorButtons {
            self.centerButtonView.containerView.backgroundColor = tintColor
            self.centerButtonView.imageView.tintColor = UIColor.whiteColor()
            self.dropShadowLayer.shadowColor = (self.centerButtonView.imageView.image != nil) ? self.shadowColor.CGColor : UIColor.clearColor().CGColor
        }
        else {
            self.centerButtonView.containerView.backgroundColor = UIColor.clearColor()
            self.centerButtonView.imageView.tintColor = tintColor
            self.dropShadowLayer.shadowColor = UIColor.clearColor().CGColor
        }
        
    }
    
    private func updateTrackColors() {
        let color = self.tintColorForActivityState(self.activityState).CGColor
        let clear = UIColor.clearColor().CGColor
        
        progressLayer.strokeColor = color
        progressLayer.fillColor = clear
        progressLayer.lineWidth = 2.5
        
        trackLayer.strokeColor = color
        trackLayer.fillColor = clear
        trackLayer.lineWidth = 1.0
    }
    
    private func updateAllColors() {
        self.updateButtonColors()
        self.updateTrackColors()
    }

    
    
    
    
    
    // MARK: - Layout
    
    
    let outlineWidth: CGFloat = 1.0
    let progressWidth: CGFloat = 2.0
    let imagePadding: CGFloat = 5.0
    
    
    /**
    Should be called once and only once. Adds layers to view heirarchy.
    */
    private func initialLayoutSetup() {
        
        self.backgroundColor = UIColor.clearColor()
        
        self.addSubview(activityContainerView)
        
        let views = ["view" : activityContainerView, "button" : self.centerButtonView.containerView]
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        
        let superlayer = activityContainerView.layer
        superlayer.addSublayer(trackLayer)
        superlayer.insertSublayer(progressLayer, above: trackLayer)
        
        self.addSubview(self.centerButtonView.containerView)
        self.bringSubviewToFront(self.centerButtonView.containerView)
        
        let metrics = ["PAD" : self.outlineWidth + self.progressWidth]
        
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(PAD)-[button]-(PAD)-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(PAD)-[button]-(PAD)-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
        
        
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
        
        // Get the rect in which we will draw the oval for the activity indicator
        // In the case our bounds are not a square, square off to the minimum direction so that our oval is always a circle
        // And obviously lets make it centered
        let frame = self.bounds
        
        self.trackLayer.frame = frame
        self.progressLayer.frame = frame
        
        let center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
        let radius = min(frame.width, frame.height) * 0.5
        let start = CGFloat(-M_PI_2)  // Start angle is pointing directly upwards on the screen. This is where progress animations will begin
        let end = CGFloat(3 * M_PI_2)
        
        trackLayer.path = UIBezierPath(arcCenter: center, radius: radius - self.progressWidth - self.outlineWidth * 0.5, startAngle: start, endAngle: end, clockwise: true).CGPath
        progressLayer.path = UIBezierPath(arcCenter: center, radius: radius - self.progressWidth * 0.5, startAngle: start, endAngle: end, clockwise: true).CGPath
        
        let buttonMask = UIBezierPath(ovalInRect: self.centerButtonView.containerView.bounds).CGPath
        self.centerButtonView.mask.path = buttonMask
        
        // Drop shadow path
        self.dropShadowLayer.shadowPath = buttonMask
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        updateForCurrentBounds()
    }
    
    /// The intrinsicContentSize if no images are provided. If images are provided this is the intrinsicContentSize.
    public let defaultContentSize: CGSize = CGSizeMake(35.0, 35.0)
    
    public override func intrinsicContentSize() -> CGSize {
        var maxW: CGFloat = self.defaultContentSize.width
        var maxH: CGFloat = self.defaultContentSize.height
        
        let totalImagePadding = 2 * (self.outlineWidth + self.progressWidth + self.imagePadding)
        
        let allImages = [inactiveImage, spinningImage, progressImage, pausedImage, completeImage]
        
        for anImage in allImages {
            if let size = anImage?.size {
                maxW = max(maxW, size.width + totalImagePadding)
                maxH = max(maxH, size.height + totalImagePadding)
            }
        }
        
        return CGSizeMake(maxW, maxH)
    }
    
    
    
    
    
    
    
    // MARK: - IB Hooks
    
    /// Image for the Inactive style.
    /// The following IBInspectible for each image state are included as hooks for interface builder. They may be used programmatically but the setImage API may be simpler.
    /// :see: setImage(forActivityStates:)
    @IBInspectable public var inactiveImage: UIImage? {
        get {
            return imagesByActivityState[.Inactive]
        }
        set {
            setImage(newValue, forActivityStates: [.Inactive])
        }
    }
    
    /// Image for the Spinning style
    @IBInspectable public var spinningImage: UIImage? {
        get {
            return imagesByActivityState[.Spinning]
        }
        set {
            setImage(newValue, forActivityStates: [.Spinning])
        }
    }
    
    /// Image for the Progress style
    @IBInspectable public var progressImage: UIImage? {
        get {
            return imagesByActivityState[.Progress]
        }
        set {
            setImage(newValue, forActivityStates: [.Progress])
        }
    }
    
    /// Image for the Paused style
    @IBInspectable public var pausedImage: UIImage? {
        get {
            return imagesByActivityState[.Paused]
        }
        set {
            setImage(newValue, forActivityStates: [.Paused])
        }
    }
    
    /// Image for the Complete style
    @IBInspectable public var completeImage: UIImage? {
        get {
            return imagesByActivityState[.Complete]
        }
        set {
            setImage(newValue, forActivityStates: [.Complete])
        }
    }
    
    
}
