//
//  ViewController.swift
//  ActivityIndicatorButtonExamples
//
//  Created by Jon Chmura on 3/9/15.
//  Copyright (c) 2015 Jon Chmura. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var activityIndicator: ActivityIndicatorButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.useSolidColorButtons = true
        self.activityIndicator.setTintColor(UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1.0), forActivityStates: [ActivityIndicatorButton.ActivityState.Complete])
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
    }
    
    @IBAction func touchUpOutside(sender: AnyObject) {
        println("TOUCH UP OUTSIDE")
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
        activityIndicator.progress = sender.value
    }
}

