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
        return activityIndicator.savedStatesCount
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return activityIndicator[mapStateForIdx(row)]!.name!
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        activityIndicator.transitionSavedState(mapStateForIdx(row), animated: true)
        updateForPickerActivityState()
    }
    
}




class ViewController: UIViewController {

    @IBOutlet var activityIndicator: ActivityIndicatorButton!
    
    @IBOutlet var stateSelector: UIPickerView!
    @IBOutlet var solidButtonSwitch: UISwitch!
    @IBOutlet var enabledSwitch: UISwitch!
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var progressSlider: UISlider!
    
    var progressBarHidden: Bool = false {
        didSet {
            progressLabel.hidden = progressBarHidden
            progressSlider.hidden = progressBarHidden
        }
    }
    
    
    struct Names {
        static let Inactive = "Inactive", Spinning = "Spinning", ProgressBar = "Progress Bar", Paused = "Paused", Complete = "Complete", Error = "Error"
    }
    
    
    func mapIdxForState(state: String) -> Int {
        switch state {
        case Names.Inactive: return 0
        case Names.Spinning: return 1
        case Names.ProgressBar: return 2
        case Names.Paused: return 3
        case Names.Complete: return 4
        default: return 5
        }
    }
    
    func mapStateForIdx(idx: Int) -> String {
        switch idx {
        case 0: return Names.Inactive
        case 1: return Names.Spinning
        case 2: return Names.ProgressBar
        case 3: return Names.Paused
        case 4: return Names.Complete
        default: return Names.Error
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.style = .Solid
        
        self.activityIndicator.saveStates([
            ActivityIndicatorButtonState(name: Names.Inactive, image: UIImage(named: "inactive")),
            ActivityIndicatorButtonState(name: Names.Spinning, progressBarStyle: .Spinning),
            ActivityIndicatorButtonState(name: Names.ProgressBar, image: UIImage(named: "pause"), progressBarStyle: .Percentage(value: 0)),
            ActivityIndicatorButtonState(name: Names.Paused, image: UIImage(named: "play"), progressBarStyle: .Percentage(value: 0)),
            ActivityIndicatorButtonState(name: Names.Complete, tintColor: UIColor(red:0.0, green:0.78, blue:0.33, alpha:1.0), image: UIImage(named: "complete")),
            ActivityIndicatorButtonState(name: Names.Error, tintColor: UIColor(red:0.84, green:0.0, blue:0.0, alpha:1.0), image: UIImage(named: "error"))
        ])
        
        self.solidButtonSwitch.on = self.activityIndicator.style == .Solid
        self.enabledSwitch.on = self.activityIndicator.enabled
        self.progressSlider.value = 0
        
        activityIndicator.transitionSavedState(Names.Inactive, animated: false)
        updateForPickerActivityState()
    }
    
    
    
    // MARK: Activity Button
    
    func nextState() {
        switch activityIndicator.activityState.name! {
        case Names.Inactive:
            activityIndicator.transitionSavedState(Names.Spinning)
            
        case Names.Spinning:
            activityIndicator.transitionSavedState(Names.ProgressBar)
            
        case Names.ProgressBar:
            activityIndicator.transitionSavedState(Names.Paused)
            
        case Names.Paused:
            activityIndicator.transitionSavedState(Names.ProgressBar)
            
        default:
            activityIndicator.transitionSavedState(Names.Inactive)
        }
        updateForPickerActivityState()
    }
    
    @IBAction func touchDown(sender: AnyObject) {
        print("TOUCH DOWN   WOO!")
    }

    @IBAction func touchDownRepeat(sender: AnyObject) {
        print("TOUCH DOWN REPEAT  WOO! WOO!")
    }
    
    @IBAction func touchDragInside(sender: AnyObject) {
        print("TOUCH DRAG INSIDE")
    }
    
    @IBAction func touchDragOutside(sender: AnyObject) {
        print("TOUCH DRAG OUTSIDE")
    }
    
    @IBAction func touchDragEnter(sender: AnyObject) {
        print("TOUCH DRAG ENTER")
    }
    
    @IBAction func touchDragExit(sender: AnyObject) {
        print("TOUCH DRAG EXIT")
    }
    
    @IBAction func touchUpInside(sender: AnyObject) {
        print("TOUCH UP INSIDE")
        
        nextState()
    }
    
    @IBAction func touchUpOutside(sender: AnyObject) {
        print("TOUCH UP OUTSIDE")
    }

    
    
    // MARK: Controls
    
    func updateForPickerActivityState() {
        let idx = mapIdxForState(activityIndicator.activityState.name!)
        if stateSelector.selectedRowInComponent(0) != idx {
            stateSelector.selectRow(idx, inComponent: 0, animated: true)
        }
        
        self.progressBarHidden = self.activityIndicator.activityState.name! != Names.ProgressBar
    }
    
    
    @IBAction func solidButtonChanged(sender: UISwitch) {
        self.activityIndicator.style = sender.on ? .Solid : .Outline
    }
    
    @IBAction func enabledValueChanged(sender: UISwitch) {
        activityIndicator.enabled = sender.on
    }
    
    @IBAction func progressValueChanged(sender: UISlider) {
        activityIndicator[Names.ProgressBar]?.setProgress(sender.value)
        activityIndicator[Names.Paused]?.setProgress(sender.value)
        
        activityIndicator.transitionSavedState(Names.ProgressBar)
    }
}

