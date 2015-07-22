//
//  ViewController.swift
//  ActivityIndicatorButtonExamples
//
//  Created by Jon Chmura on 3/9/15.
//  Copyright (c) 2015 Jon Chmura. All rights reserved.
//

import UIKit
import JPCActivityIndicatorButton



extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.states.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return states[row].name
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        activityIndicator.activityState = states[row]
    }
    
}



class ViewController: UIViewController {

    @IBOutlet var activityIndicator: ActivityIndicatorButton!
    
    @IBOutlet var stateSelector: UIPickerView!
    @IBOutlet var solidButtonSwitch: UISwitch!
    @IBOutlet var progressSlider: UISlider!
    
    var states = [
        ActivityIndicatorButtonState(name: "Inactive", image: UIImage(named: "inactive")),
        ActivityIndicatorButtonState(name: "Spinning", progressBarStyle: .Spinning),
        ActivityIndicatorButtonState(name: "Progress Bar", image: UIImage(named: "paused"), progressBarStyle: .Percentage(value: 0)),
        ActivityIndicatorButtonState(name: "Pasued", image: UIImage(named: "play")),
        ActivityIndicatorButtonState(name: "Complete", tintColor: UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1.0), image: UIImage(named: "complete")),
        ActivityIndicatorButtonState(name: "Error", tintColor: UIColor.redColor(), image: UIImage(named: "error"))
    ]
    
    struct States {
        static let Inactive = 0, Spinning = 1, ProgressBar = 2, Paused = 3, Complete = 4, Error = 5
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.style = .Solid
        
        self.solidButtonSwitch.on = self.activityIndicator.style == .Solid
        self.progressSlider.value = 0
    }
    
    
    
    // MARK: Activity Button
    
    func nextState(state: ActivityIndicatorButtonState) -> ActivityIndicatorButtonState {
        switch state.name! {
        case "Inactive":
            return states[States.Spinning]
            
        case "Spinning":
            return states[States.ProgressBar]
            
        case "Progress Bar":
            return states[States.Paused]
            
        case "Paused":
            return states[States.ProgressBar]
            
        default:
            return states[States.Inactive]
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
            self.activityIndicator.activityState = newValue
            
            var idx = find(states, activityState)!
            self.stateSelector.selectRow(idx, inComponent: 0, animated: true)
        }
    }
    
    
    @IBAction func solidButtonChanged(sender: UISwitch) {
        self.activityIndicator.style = sender.on ? .Solid : .Outline
    }
    
    @IBAction func progressValueChanged(sender: UISlider) {
        if activityIndicator.activityState.name == states[States.ProgressBar].name {
            states[States.ProgressBar].setProgress(sender.value)
            self.activityState = states[States.ProgressBar]
        }
    }
}

