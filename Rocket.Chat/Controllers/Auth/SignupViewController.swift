//
//  SignupViewController.swift
//  Rocket.Chat
//
//  Created by Rafael Kellermann Streit on 14/04/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import UIKit
import SwiftyJSON
import RealmSwift

final class SignupViewController: BaseViewController {

    internal var requesting = false

    var serverPublicSettings: AuthSettings?
    let compoundPickers = CompoundPickerViewDelegate()

    @IBOutlet weak var viewFields: UIView! {
        didSet {
            viewFields.layer.cornerRadius = 4
            viewFields.layer.borderColor = UIColor.RCLightGray().cgColor
            viewFields.layer.borderWidth = 0.5
        }
    }

    @IBOutlet weak var visibleViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var fieldsContainerVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var fieldsContainerTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var textFieldName: UITextField!
    @IBOutlet weak var textFieldEmail: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var fieldsContainer: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!

    var customTextFields: [UITextField] = []

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomFields()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )

        textFieldName.becomeFirstResponder()
    }

    func startLoading() {
        textFieldName.alpha = 0.5
        textFieldEmail.alpha = 0.5
        textFieldPassword.alpha = 0.5
        customTextFields.forEach { $0.alpha = 0.5 }

        requesting = true

        activityIndicator.startAnimating()
        textFieldName.resignFirstResponder()
        textFieldEmail.resignFirstResponder()
        textFieldPassword.resignFirstResponder()
        customTextFields.forEach { $0.resignFirstResponder() }
    }

    func stopLoading() {
        textFieldName.alpha = 1
        textFieldEmail.alpha = 1
        textFieldPassword.alpha = 1
        customTextFields.forEach { $0.alpha = 1 }

        requesting = false
        activityIndicator.stopAnimating()
    }

    // MARK: Keyboard Handlers
    override func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            visibleViewBottomConstraint.constant = keyboardSize.height
        }
    }

    override func keyboardWillHide(_ notification: Notification) {
        visibleViewBottomConstraint.constant = 0
    }

    // MARK: Request username
    fileprivate func signup() {
        startLoading()

        let name = textFieldName.text ?? ""
        let email = textFieldEmail.text ?? ""
        let password = textFieldPassword.text ?? ""

        AuthManager.signup(with: name, email, password, customFields: getCustomFieldsParams()) { [weak self] response in
            self?.stopLoading()

            if response.isError() {
                if let error = response.result["error"].dictionary {
                    Alert(
                        title: localized("error.socket.default_error.title"),
                        message: error["message"]?.string ?? localized("error.socket.default_error.message")
                    ).present()
                }
            } else {

                guard AuthSettingsManager.settings?.emailVerification == false else {
                    Alert(key: "alert.email_verification").present { _ in
                        self?.navigationController?.popViewController(animated: true)
                    }

                    return
                }

                AuthManager.auth(email, password: password, completion: { _ in
                    API.current()?.client(InfoClient.self).fetchInfo {
                        API.current()?.fetch(MeRequest()) { [weak self] response in
                            switch response {
                            case .resource(let resource):
                                let realm = Realm.current
                                try? realm?.write {
                                    if let user = resource.user {
                                        realm?.add(user, update: true)
                                    }
                                }

                                if resource.user?.username != nil {
                                    self?.dismiss(animated: true, completion: nil)
                                    AppManager.reloadApp()
                                } else {
                                    self?.performSegue(withIdentifier: "RequestUsername", sender: nil)
                                }

                            case .error: break
                            }
                        }
                    }
                })
            }
        }
    }

    private func getCustomFieldsParams() -> [String: String] {
        let pairs = customTextFields.map { (key: $0.placeholder ?? "", value: $0.text ?? "") }
        return Dictionary(keyValuePairs: pairs)
    }
}

extension SignupViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return !requesting
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if requesting {
            return false
        }

        if textField == textFieldPassword {
            signup()
        } else {
            makeNextFieldFirstResponder(after: textField)
        }
        return true
    }

    private func makeNextFieldFirstResponder(after textField: UITextField) {
        let textViews = fieldsContainer.arrangedSubviews.filter { $0 is UITextField }
        if let currentTextFieldIndex = textViews.index(of: textField) {
            let nextTextFieldIndex = textViews.index(after: currentTextFieldIndex)
            textViews[nextTextFieldIndex].becomeFirstResponder()
        }
    }
}
