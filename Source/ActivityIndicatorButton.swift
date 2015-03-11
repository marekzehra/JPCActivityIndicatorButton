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
        updateColors()
        updateForCurrentStyle(previousState: nil, animated: false)
    }
    
    
    
    
    
    // MARK: - Configuration
    
    public let animationDuration: CFTimeInterval = 0.3
    
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
        
        
        func configForState(state: ActivityState) -> (showOutline: Bool, showProgress: Bool, nextImage: UIImage?) {
            
            var showOutline = false
            var showProgress = false
            var nextImage = self.image(forActivityState: state)
            
            switch state {
            case .Inactive:
                showOutline = true
                showProgress = false
            case .Spinning:
                showOutline = false
                showProgress = true
            case .Progress:
                showOutline = true
                showProgress = true
            case .Paused:
                break
            case .Complete:
                showOutline = true
                showProgress = false
            }
            
            return (showOutline, showProgress, nextImage)
        }
        
        
        
        
        
        var nextValues = configForState(_activityState)
        var prevValues = prevState != nil ? configForState(prevState!) : (showOutline: !nextValues.showOutline, showProgress: !nextValues.showProgress, nextImage: nil)
        
        // Edge case: Paused state never modifies values
        if _activityState == .Paused {
            nextValues.showOutline = prevValues.showOutline
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
                
                self.finish(layer)
            }
            
            func finish(layer: CALayer) {
                layer.opacity = toValue
            }
        }
        
        
        
        
        var outlineOpacity: OpacityAnimation?
        var progressOpacity: OpacityAnimation?
        
        if prevValues.showOutline != nextValues.showOutline {
            outlineOpacity = OpacityAnimation(hidden: !nextValues.showOutline)
        }
        if prevValues.showProgress != nextValues.showProgress {
            progressOpacity = OpacityAnimation(hidden: !nextValues.showProgress)
        }
        var shouldAnimateImage = animated && prevValues.nextImage != nextValues.nextImage
        
        
        
        
        if animated {
            
            outlineOpacity?.addToLayer(self.outlineLayer, duration: self.animationDuration)
            progressOpacity?.addToLayer(self.progressLayer, duration: self.animationDuration)
        }
        else {
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            outlineOpacity?.finish(self.outlineLayer)
            progressOpacity?.finish(self.progressLayer)
            CATransaction.commit()
        }
        
        
        let nextButtonView = self.centerButtonView
        self.centerButtonView.imageView.image = nextValues.nextImage
        
        
        // If image has changed and we're animating...
        if shouldAnimateImage {
            
            let duration = 0.25
            
            let bounds = nextButtonView.containerView.bounds
            let center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
            let compressed = UIBezierPath(arcCenter: center, radius: 0.0, startAngle: 0.0, endAngle: CGFloat(M_PI * 2), clockwise: true).CGPath
            let expanded = UIBezierPath(ovalInRect: bounds).CGPath
            
            // We're going to a nil image. Animate away the old one
            if nextValues.nextImage == nil {
                
                let completion = { () -> Void in
                    self.updateColors()
                }
                
                CATransaction.begin()
                
                CATransaction.setCompletionBlock(completion)
                
                let expandNewButton = CABasicAnimation(keyPath: "path")
                expandNewButton.fromValue = expanded
                expandNewButton.toValue = compressed
                expandNewButton.duration = duration
                
                nextButtonView.containerView.layer.mask.addAnimation(expandNewButton, forKey: "expand")
                
                CATransaction.commit()
            }
            else {
                
                nextButtonView.updateColors(self.tintColorForActivityState(self.activityState), tintBackground: self.tintControlBackground)
                if let prevState = prevState {
                    self.outlineLayer.fillColor = (self.tintControlBackground && prevValues.nextImage != nil) ? self.tintColorForActivityState(prevState).CGColor : UIColor.clearColor().CGColor
                }
                
                let completion = { () -> Void in
                    self.updateColors()
                }
                
                CATransaction.begin()
                
                CATransaction.setCompletionBlock(completion)
                
                let expandNewButton = CABasicAnimation(keyPath: "path")
                expandNewButton.fromValue = compressed
                expandNewButton.toValue = expanded
                expandNewButton.duration = duration
                
                nextButtonView.containerView.layer.mask.addAnimation(expandNewButton, forKey: "expand")
                
                CATransaction.commit()
            }
            
        }
        else {
            updateColors()
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
    
    
    /// If true the circular background of this control is colored with the tint color and the image is colored white. Otherwise the background is clear and the image is tinted. Image color is only adjusted if it is a template image.
    @IBInspectable public var tintControlBackground: Bool = false {
        didSet {
            self.updateColors()
        }
    }
    
    /// Overrides the tintColor property for the current state. 
    /// :see: setTintColorForActivityState
    @IBInspectable public var tintColorForActivityState: UIColor {
        get {
            return self.tintColorForActivityState(self.activityState)
        }
        set {
            self.setTintColor(newValue, forActivityStates: [self.activityState])
        }
    }
    
    private var tintColorsByState = [ActivityState : UIColor]()
    
    public func tintColorForActivityState(state: ActivityState) -> UIColor {
        let color = self.tintColorsByState[state]
        return color == nil ? self.tintColor : color
    }
    
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
    
    
    /// Add an image to the center of the control for all Styles. If an image is set for any of the other styles it will override this one while in that style. Template image are colored with this controls tint color. If highlighted image is provided it will be show while this control is in the "highlighted" state.
    @IBInspectable public var image: UIImage?
    
    
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
    
    private var imagesByActivityState = [ActivityState : UIImage]()
    
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
    
    public func image(forActivityState state: ActivityState) -> UIImage? {
        var image = imagesByActivityState[state]
        return image != nil ? image : self.image
    }
    
    
    
    
    
    
    // MARK: - UI (Private)
    
    
    private class ButtonView {
    
        let containerView = UIView()
        var imageView: UIImageView!
        let mask = CAShapeLayer()
        
        init(image: UIImage?) {
            
            imageView = UIImageView(image: image)
            
            containerView.setTranslatesAutoresizingMaskIntoConstraints(false)
            imageView.setTranslatesAutoresizingMaskIntoConstraints(false)
            
            containerView.addSubview(imageView)
            containerView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .CenterX, relatedBy: .Equal, toItem: containerView, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
            containerView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .CenterY, relatedBy: .Equal, toItem: containerView, attribute: .CenterY, multiplier: 1.0, constant: 0.0))
            
            mask.fillColor = UIColor.whiteColor().CGColor
            containerView.layer.mask = mask
        }
        
        func updateColors(color: UIColor, tintBackground: Bool) {
            
            let tintColor = imageView.image == nil ? UIColor.clearColor() : color
            
            if tintBackground {
                containerView.backgroundColor = tintColor
                imageView.tintColor = UIColor.whiteColor()
            }
            else {
                containerView.backgroundColor = UIColor.clearColor()
                imageView.tintColor = tintColor
            }
        }
        
        func removeFromSuperview() {
            containerView.removeFromSuperview()
        }
        
    }
    
    
    /// Used to display the image
    private var centerButtonView: ButtonView!
    
    /// View containing the layers. Makes it easier to keep the layers in the right zOrder.
    private lazy var activityContainerView: UIView = {
        let view = UIView()
        view.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.backgroundColor = UIColor.clearColor()
        return view
    }()
    
    /// The spinning activity indicator
    private lazy var progressLayer: CAShapeLayer = CAShapeLayer()
    
    /// The outline around the progressLayer when state is Normal or Progress
    private lazy var outlineLayer: CAShapeLayer = CAShapeLayer()
    
    /// Displays a material design style animation when the control is highlighted
    private lazy var hitAnimationLayer: CAShapeLayer = CAShapeLayer()
    
    /// Masks the hitAnimationLayer so it doesn't overlap the bounds of the outline layer.
    private lazy var hitAnimationLayerMask: CAShapeLayer = CAShapeLayer()
    
    
    
    
    // MARK: - Theming
    
    override public func tintColorDidChange() {
        super.tintColorDidChange()
        
        updateColors()
    }
    
    private func updateColors() {
        let color = self.tintColorForActivityState
        let clear = UIColor.clearColor().CGColor
        
        self.centerButtonView.updateColors(color, tintBackground: self.tintControlBackground)
        
        progressLayer.strokeColor = color.CGColor
        progressLayer.fillColor = clear
        progressLayer.lineWidth = 2.5
        
        outlineLayer.strokeColor = color.CGColor
        outlineLayer.fillColor = clear
        outlineLayer.lineWidth = 1.0
    }

    
    
    
    
    
    // MARK: - Layout
    
    
    let outlineWidth: CGFloat = 1.0
    let progressWidth: CGFloat = 2.0
    let imagePadding: CGFloat = 5.0
    
    
    /**
    Should be called once and only once. Adds layers to view heirarchy.
    */
    private func initialLayoutSetup() {
        
        self.addSubview(activityContainerView)
        
        let views = ["view" : activityContainerView]
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        
        let superlayer = activityContainerView.layer
        superlayer.addSublayer(outlineLayer)
        superlayer.insertSublayer(progressLayer, above: outlineLayer)
        superlayer.insertSublayer(hitAnimationLayer, below: outlineLayer)
        hitAnimationLayer.mask = hitAnimationLayerMask
        
        self.centerButtonView = ButtonView(image: self.image(forActivityState: self.activityState))
        self.addButtonView(self.centerButtonView)
    }
    
    /**
    Should call this to add a new button view to the view heirarchy
    
    :param: buttonView The new button view
    */
    private func addButtonView(buttonView: ButtonView) {
        
        self.addSubview(buttonView.containerView)
        self.bringSubviewToFront(buttonView.containerView)
        
        let views = ["button" : buttonView.containerView]
        let metrics = ["PAD" : self.outlineWidth + self.progressWidth]
        
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(PAD)-[button]-(PAD)-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(PAD)-[button]-(PAD)-|", options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
    }
    
    /**
    Should be called when bounds change to update paths of shape layers.
    */
    private func updateForCurrentBounds() {
        
        // Get the rect in which we will draw the oval for the activity indicator
        // In the case our bounds are not a square, square off to the minimum direction so that our oval is always a circle
        // And obviously lets make it centered
        let frame = self.bounds
        
        self.outlineLayer.frame = frame
        self.progressLayer.frame = frame
        
        let center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
        let radius = min(frame.width, frame.height) * 0.5
        let start = CGFloat(-M_PI_2)  // Start angle is pointing directly upwards on the screen. This is where progress animations will begin
        let end = CGFloat(3 * M_PI_2)
        
        outlineLayer.path = UIBezierPath(arcCenter: center, radius: radius - self.progressWidth - self.outlineWidth * 0.5, startAngle: start, endAngle: end, clockwise: true).CGPath
        progressLayer.path = UIBezierPath(arcCenter: center, radius: radius - self.progressWidth * 0.5, startAngle: start, endAngle: end, clockwise: true).CGPath
        
        let buttonMask = UIBezierPath(ovalInRect: self.centerButtonView.containerView.bounds).CGPath
        self.centerButtonView.mask.path = buttonMask
        hitAnimationLayerMask.path = buttonMask
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
        
        let allImages = [image, inactiveImage, spinningImage, progressImage, pausedImage, completeImage]
        
        for anImage in allImages {
            if let size = anImage?.size {
                maxW = max(maxW, size.width + totalImagePadding)
                maxH = max(maxH, size.height + totalImagePadding)
            }
        }
        
        return CGSizeMake(maxW, maxH)
    }
    
    
}
