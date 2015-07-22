//
//  ViewController.swift
//  ActivityIndicatorButtonExamples
//
//  Created by Jon Chmura on 3/9/15.
//  Copyright (c) 2015 Jon Chmura. All rights reserved.
//

import UIKit
import JPCActivityIndicatorButton

class ViewController: UIViewController {

    @IBOutlet var activityIndicator: ActivityIndicatorButton!
    
    @IBOutlet var stateSelector: UISegmentedControl!
    @IBOutlet var solidButtonSwitch: UISwitch!
    @IBOutlet var progressSlider: UISlider!
    
    
    struct States {
        static let defaultTintColor = UIColor.blueColor()
        static let trackColor = UIColor.lightGrayColor()
        
        static let Inactive = ActivityIndicatorButtonState(image: UIImage(named: "inactive"))
        static let Spinning = ActivityIndicatorButtonState(progressBarStyle: .Spinning)
        static var Progress = ActivityIndicatorButtonState(image: UIImage(named: "paused"), progressBarStyle: .Percentage(value: 0))
        static let Paused = ActivityIndicatorButtonState(image: UIImage(named: "play"))
        static let Complete = ActivityIndicatorButtonState(tintColor: UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1.0), image: UIImage(named: "complete"))
        static let Error = ActivityIndicatorButtonState(tintColor: UIColor.redColor(), image: UIImage(named: "error"))
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.style = .Solid
        
        self.solidButtonSwitch.on = self.activityIndicator.style == .Solid
        self.progressSlider.value = 0
    }
    
    
    
    // MARK: Activity Button
    
    func nextState(state: ActivityIndicatorButtonState) -> ActivityIndicatorButtonState {
        switch state {
        case States.Inactive:
            return States.Spinning
            
        case States.Spinning:
            return States.Progress
            
        case States.Progress:
            return States.Complete
            
        case States.Paused:
            return States.Progress
            
        default:
            return States.Inactive
        }
    }
    
    @IBAction func touchDown(sender: AnyObject) {
        println("TOUCH DOWN   WOO!")
    }

    @IBAction func touchDownRepeat(sender: AnyObject) {
        println("TOUCH DOWN REPEAT  WOO! WOO!")
    }
    
    @IBAction func touchDragInside(sender: AnyObject) {
        println("TOUCH DRAG INSIDE")
    }
    
    @IBAction func touchDragOutside(sender: AnyObject) {
        println("TOUCH DRAG OUTSIDE")
    }
    
    @IBAction func touchDragEnter(sender: AnyObject) {
        println("TOUCH DRAG ENTER")
    }
    
    @IBAction func touchDragExit(sender: AnyObject) {
        println("TOUCH DRAG EXIT")
    }
    
    @IBAction func touchUpInside(sender: AnyObject) {
        println("TOUCH UP INSIDE")
        
        self.activityState = nextState(self.activityIndicator.activityState)
    }
    
    @IBAction func touchUpOutside(sender: AnyObject) {
        println("TOUCH UP OUTSIDE")
    }

    
    
    // MARK: Controls
    
    var activityState: ActivityIndicatorButtonState {
        get {
            return self.activityIndicator.activityState
        }
        set {
            
            self.activityIndicator.activityState = activityState
            
            switch activityState {
            case States.Inactive:
                self.stateSelector.selectedSegmentIndex = 0
                
            case States.Spinning:
                self.stateSelector.selectedSegmentIndex = 1
                
            case States.Progress:
                self.stateSelector.selectedSegmentIndex = 2
                
            case States.Paused:
                self.stateSelector.selectedSegmentIndex = 3
                
            case States.Complete:
                self.stateSelector.selectedSegmentIndex = 4
                
            default:
                self.stateSelector.selectedSegmentIndex = 5
            }
        }
    }
    
    
    @IBAction func solidButtonChanged(sender: UISwitch) {
        self.activityIndicator.style = sender.on ? .Solid : .Outline
    }
    
    @IBAction func stateValueChanged(sender: UISegmentedControl) {
        
        var newState: ActivityIndicatorButtonState!
        switch sender.selectedSegmentIndex {
        case 0:
            newState = States.Inactive
        case 1:
            newState = States.Spinning
        case 2:
            newState = States.Progress
        case 3:
            newState = States.Paused
        case 4:
            newState = States.Complete
        default:
            newState = States.Error
        }
        
        activityIndicator.activityState = newState
    }
    
    @IBAction func progressValueChanged(sender: UISlider) {
        if activityIndicator.activityState == States.Progress {
            States.Progress.progressBarStyle = .Percentage(value: sender.value)
            self.activityState = States.Progress
        }
    }
}

