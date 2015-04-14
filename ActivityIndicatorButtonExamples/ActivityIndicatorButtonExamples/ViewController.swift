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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.useSolidColorButtons = true
        self.activityIndicator.progress = 0.45
        self.activityIndicator.setTrackColor(UIColor.lightGrayColor(), forActivityStates: [.Spinning, .Progress])
        self.activityIndicator.setTintColor(UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1.0), forActivityStates: [.Complete])
        
        self.solidButtonSwitch.on = self.activityIndicator.useSolidColorButtons
        self.progressSlider.value = self.activityIndicator.progress
    }
    
    
    
    // MARK: Activity Button
    
    func nextState(state: ActivityIndicatorButton.ActivityState) -> ActivityIndicatorButton.ActivityState {
        switch state {
        case .Inactive: return .Spinning
        case .Spinning: return .Progress
        case .Progress: return .Paused
        case .Paused: return .Progress
        case .Complete: return .Inactive
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
        
        let state = nextState(self.activityIndicator.activityState)
        self.activityIndicator.transition(toActivityState: state, animated: true)
        self.setSliderActivityState(state)
    }
    
    @IBAction func touchUpOutside(sender: AnyObject) {
        println("TOUCH UP OUTSIDE")
    }

    
    
    // MARK: Controls
    
    func setSliderActivityState(state: ActivityIndicatorButton.ActivityState) {
        switch state {
        case .Inactive:
            self.stateSelector.selectedSegmentIndex = 0
        case .Spinning:
            self.stateSelector.selectedSegmentIndex = 1
        case .Progress:
            self.stateSelector.selectedSegmentIndex = 2
        case .Paused:
            self.stateSelector.selectedSegmentIndex = 3
        case .Complete:
            self.stateSelector.selectedSegmentIndex = 4
        }
    }
    
    @IBAction func solidButtonChanged(sender: UISwitch) {
        self.activityIndicator.useSolidColorButtons = sender.on
        self.activityIndicator.transition(toActivityState: self.activityIndicator.activityState, animated: false)
    }
    
    @IBAction func stateValueChanged(sender: UISegmentedControl) {
        
        var newState: ActivityIndicatorButton.ActivityState!
        switch sender.selectedSegmentIndex {
        case 0:
            newState = .Inactive
        case 1:
            newState = .Spinning
        case 2:
            newState = .Progress
        case 3:
            newState = .Paused
        default:
            newState = .Complete
        }
        
        activityIndicator.transition(toActivityState: newState, animated: true)
    }
    
    @IBAction func progressValueChanged(sender: UISlider) {
        activityIndicator.progress = sender.value // Don't use animation here. (Or in any situation where there will be continuous updates. It won't crash but its not neccessary)
    }
}

