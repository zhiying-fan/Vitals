// Copyright 2023 The MediaPipe Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import AVFoundation
import UIKit
import Vitals

/**
 * The view controller is responsible for performing detection on incoming frames from the live camera and presenting the frames with the
 * landmark of the landmarked faces to the user.
 */
class CameraViewController: UIViewController {
  private struct Constants {
    static let edgeOffset: CGFloat = 2.0
  }
  
  @IBOutlet weak var previewView: UIView!
  @IBOutlet weak var cameraUnavailableLabel: UILabel!
  @IBOutlet weak var resumeButton: UIButton!
  @IBOutlet weak var progressView: UIProgressView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  private var isSessionRunning = false
  
  private var flagCaching = false
  private let cacheSolution = VitalsSDK.shared.getSolution(callbackQueue: DispatchQueue.main)
  private var timer: Timer?
  private var progress = 0.0
  
  // MARK: Controllers that manage functionality
  // Handles all the camera related functionality
  private lazy var cameraFeedService = CameraFeedService(previewView: previewView)
  
#if !targetEnvironment(simulator)
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    cameraFeedService.startLiveCameraSession {[weak self] cameraConfiguration in
      DispatchQueue.main.async {
        switch cameraConfiguration {
        case .failed:
          self?.presentVideoConfigurationErrorAlert()
        case .permissionDenied:
          self?.presentCameraPermissionsDeniedAlert()
        default:
          break
        }
      }
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    cameraFeedService.stopSession()
    cacheSolution.release { error in
      print(error as Any)
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    cameraFeedService.delegate = self
    
    cacheSolution.create { [weak self] error in
      if let error {
        DispatchQueue.main.async {
          self?.presentMessageAlert(text: error.localizedDescription)
        }
      }
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    cameraFeedService.updateVideoPreviewLayer(toFrame: previewView.bounds)
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    cameraFeedService.updateVideoPreviewLayer(toFrame: previewView.bounds)
  }
#endif
  
  // Resume camera session when click button resume
  @IBAction func onClickResume(_ sender: Any) {
    cameraFeedService.resumeInterruptedSession {[weak self] isSessionRunning in
      if isSessionRunning {
        self?.resumeButton.isHidden = true
        self?.cameraUnavailableLabel.isHidden = true
      }
    }
  }
  
  @IBAction func onClickStart(_ sender: Any) {
    flagCaching = true
    
    progressView.isHidden = false
    startTimer()
  }
  
  @IBAction func onClickEnd(_ sender: Any) {
    flagCaching = false
    
    stopTimer()
    
    progressView.isHidden = true
    activityIndicator.isHidden = false
    activityIndicator.startAnimating()
    
    cacheSolution.analyze { [weak self] result in
      switch result {
      case .success(let measureResult):
        DispatchQueue.main.async {
          self?.presentMessageAlert(text: measureResult.description)
          self?.activityIndicator.stopAnimating()
        }
      case .failure(let error):
        DispatchQueue.main.async {
          self?.presentMessageAlert(text: error.localizedDescription)
          self?.activityIndicator.stopAnimating()
        }
      }
    }
  }
  
  private func startTimer() {
    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
  }
  
  @objc private func updateProgress() {
    let timeout = Double(cacheSolution.getTimeout() / 1000)
    
    if progress < timeout {
      progress += 1
      progressView.progress = Float(progress / timeout)
    }
  }
  
  private func stopTimer() {
    timer?.invalidate()
    timer = nil
    progress = 0.0
  }
  
  private func presentCameraPermissionsDeniedAlert() {
    let alertController = UIAlertController(
      title: "Camera Permissions Denied",
      message:
        "Camera permissions have been denied for this app. You can change this by going to Settings",
      preferredStyle: .alert)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
      UIApplication.shared.open(
        URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
    }
    alertController.addAction(cancelAction)
    alertController.addAction(settingsAction)
    
    present(alertController, animated: true, completion: nil)
  }
  
  private func presentVideoConfigurationErrorAlert() {
    let alert = UIAlertController(
      title: "Camera Configuration Failed",
      message: "There was an error while configuring camera.",
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    
    self.present(alert, animated: true)
  }
  
  private func presentMessageAlert(text: String) {
    let alert = UIAlertController(
      title: "",
      message: text,
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    
    self.present(alert, animated: true)
  }
}

extension CameraViewController: CameraFeedServiceDelegate {
  func didOutput(sampleBuffer: CMSampleBuffer, orientation: UIImage.Orientation) {
    let now = Date().timeIntervalSince1970 * 1000
    if flagCaching {
      cacheSolution.postFrame(sampleBuffer: sampleBuffer, frameTimestamp: now)
    }
  }
  
  // MARK: Session Handling Alerts
  func sessionWasInterrupted(canResumeManually resumeManually: Bool) {
    // Updates the UI when session is interupted.
    if resumeManually {
      resumeButton.isHidden = false
    } else {
      cameraUnavailableLabel.isHidden = false
    }
  }
  
  func sessionInterruptionEnded() {
    // Updates UI once session interruption has ended.
    cameraUnavailableLabel.isHidden = true
    resumeButton.isHidden = true
  }
  
  func didEncounterSessionRuntimeError() {
    // Handles session run time error by updating the UI and providing a button if session can be
    // manually resumed.
    resumeButton.isHidden = false
  }
}

// MARK: - AVLayerVideoGravity Extension
extension AVLayerVideoGravity {
  var contentMode: UIView.ContentMode {
    switch self {
    case .resizeAspectFill:
      return .scaleAspectFill
    case .resizeAspect:
      return .scaleAspectFit
    case .resize:
      return .scaleToFill
    default:
      return .scaleAspectFill
    }
  }
}
