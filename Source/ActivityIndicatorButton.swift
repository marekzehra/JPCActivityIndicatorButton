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
    private func updateForCurrentStyle(previousState prevState: ActivityState, animated: Bool) {
        
        
        func configForState(state: ActivityState) -> (showOutline: Bool, showProgress: Bool, nextImage: UIImage?) {
            
            var showOutline = false
            var showProgress = false
            var nextImage = self.image(forActivityState: state)
            
            switch state {
            case .Inactive:
                showOutline = true
                showProgress = false
            case .Spinning:
                showProgress = false
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
        var prevValues = configForState(prevState)
        
        
        
        
        
        func getNextImageView() -> UIImageView? {
            if let nextImage = nextValues.nextImage {
                let theImageView = UIImageView(image: nextImage)
                
                self.addSubview(theImageView)
                self.sendSubviewToBack(theImageView)
                
                theImageView.setTranslatesAutoresizingMaskIntoConstraints(false)
                self.addConstraint(NSLayoutConstraint(item: theImageView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
                self.addConstraint(NSLayoutConstraint(item: theImageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0))
                
                return theImageView
            }
            return nil
        }
        
        struct OpacityAnimation {
            let toValue: CGFloat
            let fromValue: CGFloat
            
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
            }
        }
        
        
        
        
        var outlineOpacity: OpacityAnimation?
        var progressOpacity: OpacityAnimation?
        var updateImage = false
        
        if prevValues.showOutline != nextValues.showOutline {
            outlineOpacity = OpacityAnimation(hidden: !nextValues.showOutline)
        }
        if prevValues.showProgress != nextValues.showProgress {
            progressOpacity = OpacityAnimation(hidden: !nextValues.showProgress)
        }
        updateImage = prevValues.nextImage != nextValues.nextImage
        
        
        
        if animated {
            
            outlineOpacity?.addToLayer(self.outlineLayer, duration: self.animationDuration)
            progressOpacity?.addToLayer(self.progressLayer, duration: self.animationDuration)
        }
        
        if updateImage {
            
            let nextImageView = getNextImageView()
            
            let completion = { (finished: Bool) -> Void in
                if let currentImageView = self.imageView {
                    currentImageView.removeFromSuperview()
                }
                self.imageView = nextImageView
            }
            
            if animated {
                
                nextImageView?.alpha = 0.0
                nextImageView?.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
                UIView.animateWithDuration(self.animationDuration, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.allZeros, animations: { () -> Void in
                    
                    print("Animating Image")
                    self.imageView?.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
                    self.imageView?.alpha = 0.0
                    
                    nextImageView?.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
                    nextImageView?.alpha = 1.0
                    
                }, completion: completion)
            }
            else {
                completion(true)
            }
            
        }
        
        self.updateSpinningAnimation()
        self.updateProgress(fromValue: 0.0, animated: animated)
    }
    
    private var _progress: CGFloat = 0.0
    
    /// A float between 0.0 and 1.0 specifying the progress amount in the Progress state. This is displayed clockwise where 1.0 fills the whole circle. Equivalent to calling setProgress(animated: false).
    /// :see: setProgress(animated:)
    public var progress: CGFloat {
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
    public func setProgress(progress: CGFloat, animated: Bool) {
        let prevValue = _progress
        _progress = progress
        
        updateProgress(fromValue: prevValue, animated: animated)
    }
    
    private func updateProgress(fromValue prevValue: CGFloat, animated: Bool) {
        if activityState == .Progress {
            
            let anim = CABasicAnimation(keyPath: "strokeEnd")
            anim.fromValue = prevValue
            anim.toValue = _progress
            anim.duration = 0.2
            self.progressLayer.addAnimation(anim, forKey: "progress")
            
            self.progressLayer.strokeEnd = _progress
        }
    }
    
    private func updateSpinningAnimation() {
        
        let kStrokeEndAnim = "spinning_strokeEnd"
        let kRotationAnim = "spinning_rotation"
        
        self.progressLayer.removeAnimationForKey(kStrokeEndAnim)
        self.progressLayer.removeAnimationForKey(kRotationAnim)
        if activityState == .Spinning {
         
            let strokeEndAnim = CABasicAnimation(keyPath: "strokeEnd")
            strokeEndAnim.fromValue = 0.0
            strokeEndAnim.toValue = 1.0
            strokeEndAnim.duration = 1.0
            
            let rotationAnim = CABasicAnimation(keyPath: "transform")
            rotationAnim.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
            rotationAnim.toValue = NSValue(CATransform3D: CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(CGFloat(2*M_PI))))
            rotationAnim.duration = 1.5
            
            self.progressLayer.addAnimation(strokeEndAnim, forKey: kStrokeEndAnim)
            self.progressLayer.addAnimation(rotationAnim, forKey: kRotationAnim)
        }
    }
    
    
    
    
    // MARK: - Configuration (Images)
    
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
    }
    
    public func image(forActivityState state: ActivityState) -> UIImage? {
        var image = imagesByActivityState[state]
        return image != nil ? image : self.image
    }
    
    
    
    
    
    
    // MARK: - UI (Private)
    
    /// Used to display the image
    private var imageView: UIImageView?
    
    /// View containing the layers. Makes it easier to keep the layers in the right zOrder.
    private lazy var activityContainerView: UIView = {
        let view = UIView()
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
        let color = tintColor.CGColor
        let clear = UIColor.clearColor().CGColor
        
        imageView?.tintColor = tintColor
        
        progressLayer.strokeColor = color
        progressLayer.fillColor = clear
        
        outlineLayer.strokeColor = color
        outlineLayer.fillColor = clear
    }

    
    
    
    
    
    // MARK: - Layout
    
    /**
    Should be called once and only once. Adds layers to view heirarchy.
    */
    private func initialLayoutSetup() {
        println("Doing initial setup")
        
        self.addSubview(activityContainerView)
        
        let views = ["view" : activityContainerView]
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: views))
        
        let superlayer = activityContainerView.layer
        superlayer.addSublayer(outlineLayer)
        superlayer.insertSublayer(progressLayer, above: outlineLayer)
        superlayer.insertSublayer(hitAnimationLayer, below: outlineLayer)
        hitAnimationLayer.mask = hitAnimationLayerMask
    }
    
    /**
    Should be called when bounds change to update paths of shape layers.
    */
    private func updateForCurrentBounds() {
        
        // Get the rect in which we will draw the oval for the activity indicator
        // In the case our bounds are not a square, square off to the minimum direction so that our oval is always a circle
        // And obviously lets make it centered
        let frame = activityContainerView.frame
        let minDim = min(frame.width, frame.height)
        let centeredFrame = CGRectInset(frame, minDim - frame.width, minDim - frame.height)
        
        let path = UIBezierPath(ovalInRect: centeredFrame).CGPath
        
        outlineLayer.path = path
        progressLayer.path = path
        hitAnimationLayerMask.path = path
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        updateForCurrentBounds()
    }
    
    /// The intrinsicContentSize if no images are provided. If images are provided this is the intrinsicContentSize.
    public let defaultContentSize: CGSize = CGSizeMake(35.0, 35.0)
    
    public override func intrinsicContentSize() -> CGSize {
        var maxW: CGFloat = 0.0
        var maxH: CGFloat = 0.0
        
        let allImages = [image, inactiveImage, spinningImage, progressImage, pausedImage, completeImage]
        
        for anImage in allImages {
            if let size = anImage?.size {
                maxW = max(maxW, size.width)
                maxH = max(maxH, size.height)
            }
        }
        
        return CGSizeMake(max(self.defaultContentSize.width, maxW), max(self.defaultContentSize.height, maxH))
    }
    
    
}
