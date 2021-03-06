//
//  ModalViewController.swift
//  ModalViewController
//
//  Created by ZJaDe on 2018/10/26.
//  Copyright © 2018 zjade. All rights reserved.
//

import UIKit

open class ModalViewController: UIViewController, ModalPresentationDelegate, ModalAnimatedTransitioningDeledate {
    open override func loadView() {
        super.loadView()
        self.view = ModalRootView(frame: self.view.frame)
    }
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configInit()
    }
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -
    /// ZJaDe: show时 因为不是present(:::) 所以presentingViewController为nil 所以需要手动记录下
    private weak var modalContainer: UIViewController?

    public weak var presentationDelegate: ModalPresentationDelegate?
    public weak var animatedTransitioningDelegate: ModalAnimatedTransitioningDeledate?
    /// ZJaDe: 显示的过程中需要临时存储下，防止多次创建
    private var tempPresentationController: PresentationController?
    open func configInit() {
        self.presentationDelegate = self
        self.animatedTransitioningDelegate = self
        /** ZJaDe:
            因为PresentationController初始化后会强引用presentedViewController，为了避免循环引用，还要保证PresentationController不被初始化多次，present之前先持有 PresentationController 对象 dismissed后释放
         */
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        addChildView()
        configLayout()
        view.setNeedsLayout()
        updatePreferredContentSize(traitCollection: self.traitCollection)
        reloadData()
    }

    public var isShowing: Bool {
        return self.getPresenting != nil
    }
    // MARK: -
    public var getPresenting: UIViewController? {
        return self.modalContainer ?? self.presentingViewController
    }
    /// ZJaDe: 重新加载
    open func reloadData() {

    }
    /// ZJaDe: 不要直接调用该方法，重写添加子view
    open func addChildView() {

    }
    /// ZJaDe: 不要直接调用该方法，重写设置约束
    open func configLayout() {

    }

    /// ZJaDe: 点击 dimmingView
    @objc open func dimmingViewTapped() {
        cancel()
    }

    public var didCancel:(() -> Void)?
    open func cancel(animated: Bool = true, completion: (() -> Void)? = nil) {
        if let container = self.parent as? ModalContainerProtocol {
            container.hide(self, animated: animated, completion)
        } else {
            self.dismiss(animated: animated, completion: completion)
        }
        self.didCancel?()
    }
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.view.window == nil {
            /** ZJaDe:
             有时候是show出来的，生命周期结束时没有cancel，为了防止循环引用，这时需要cancel下；
             但是有可能是self已经不在视图层次的原因，只cancel的话还是会导致self和presentationController循环引用，所以需要手动置为nil
             */
            cancel()
            self.presentationController?.setValue(nil, forKey: "presentedViewController")
        }
    }

    open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        updatePreferredContentSize(traitCollection: newCollection)
    }
    open func updatePreferredContentSize(traitCollection: UITraitCollection) {
        self.preferredContentSize = (self.presentedViewController ?? self).view.frame.size
    }

    // MARK: - UIViewControllerTransitioningDelegate
    open var presentationControllerClass: PresentationController.Type {
        return PresentationController.self
    }
    func createPresentationCon(presenting presentingViewController: UIViewController? = nil) -> PresentationController {
        return presentationControllerClass.init(self, presenting: presentingViewController)
    }
    func createPresentationCon(modalContainer: UIViewController) -> PresentationController {
        self.modalContainer = modalContainer
        let result = presentationControllerClass.init(self, modalContainer: modalContainer)
        self.tempPresentationController = result
        return result
    }
    open func createAnimatedTransitioning(isPresenting: Bool) -> ModalAnimatedTransitioning {
        return ModalAnimatedTransitioning(isPresenting, self.animatedTransitioningDelegate)
    }
    // MARK: - ModalPresentationDelegate
    public enum AnimateOption {
        case topOutToCenter, bottomOutToCenter, leftOutToCenter, rightOutToCenter
        case topOutIn, bottomOutIn, leftOutIn, rightOutIn
        case centerInOut
        case none
    }
    open var animateOption: AnimateOption {
        return .bottomOutToCenter
    }
    open func config(wrappingView: PresentationController.WrappingView) {
        switch self.animateOption {
        case .topOutIn:
            wrappingView.layer.shadowOffset = CGSize(width: 0, height: 6)
        case .bottomOutIn:
            wrappingView.layer.shadowOffset = CGSize(width: 0, height: -6)
        case .leftOutIn:
            wrappingView.layer.shadowOffset = CGSize(width: 6, height: 0)
        case .rightOutIn:
            wrappingView.layer.shadowOffset = CGSize(width: -6, height: 0)
        case .centerInOut, .topOutToCenter, .bottomOutToCenter, .leftOutToCenter, .rightOutToCenter, .none:
            wrappingView.layer.shadowOffset = CGSize(width: 0, height: 0)
        }
        wrappingView.layer.shadowOpacity = 0.44
        wrappingView.layer.shadowRadius = 13
    }
    open func config(dimmingView: PresentationController.DimmingView) {

    }
    open func presentedViewFrame(_ containerViewBounds: CGRect, _ presentedViewContentSize: CGSize) -> CGRect {
        var result = containerViewBounds
        result.size = presentedViewContentSize
        var x = (containerViewBounds.width - result.width) / 2
        var y = (containerViewBounds.height - result.height) / 2
        result.origin = CGPoint(x: x, y: y)
        switch self.animateOption {
        case .topOutIn:
            y = 0
        case .bottomOutIn:
            y = containerViewBounds.maxY - result.height
        case .leftOutIn:
            x = 0
        case .rightOutIn:
            x = containerViewBounds.maxX - result.width
        case .none, .centerInOut, .topOutToCenter, .bottomOutToCenter, .leftOutToCenter, .rightOutToCenter:
            break
        }
        result.origin = CGPoint(x: x, y: y)
        return result
    }
    public enum State: Int {
        case 还未显示
        case 将要显示
        case 已经显示
        case 将要消失
        case 已经消失
    }
    public private(set) var state: State = .还未显示
    open func presentationTransitionWillBegin() {
        self.state = .将要显示
    }
    open func presentationTransitionDidEnd(_ completed: Bool) {
        self.state = .已经显示
    }
    open func dismissalTransitionWillBegin() {
        self.state = .将要消失
    }
    open func dismissalTransitionDidEnd(_ completed: Bool) {
        self.tempPresentationController = nil
        self.state = .已经消失
    }
    // MARK: - ModalAnimatedTransitioningDeledate
    open func calculateToViewInitialFrame(finalFrame: CGRect) -> CGRect {
        switch self.animateOption {
        case .topOutIn, .topOutToCenter:
            return finalFrame.offsetBy(dx: 0, dy: -finalFrame.height)
        case .bottomOutIn, .bottomOutToCenter:
            return finalFrame.offsetBy(dx: 0, dy: finalFrame.height)
        case .leftOutIn, .leftOutToCenter:
            return finalFrame.offsetBy(dx: -finalFrame.width, dy: 0)
        case .rightOutIn, .rightOutToCenter:
            return finalFrame.offsetBy(dx: finalFrame.width, dy: 0)
        case .centerInOut:
            return CGRect(origin: CGPoint(x: finalFrame.midX, y: finalFrame.midY), size: CGSize.zero)
        case .none:
            return finalFrame
        }
    }
    open func calculateFromViewFinalFrame(initialFrame: CGRect) -> CGRect {
        return calculateToViewInitialFrame(finalFrame: initialFrame)
    }
}

extension ModalViewController: UIViewControllerTransitioningDelegate {
    public func updateViewsFrame() {
        (self.presentationController as? PresentationController)?.updateViewsFrame()
    }
    public final func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        assert(self == presented, "presentedViewController错误")
        if self.tempPresentationController == nil {
            self.tempPresentationController = createPresentationCon(presenting: presenting)
        }
        return self.tempPresentationController
    }
    public final func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self.createAnimatedTransitioning(isPresenting: true)
    }
    public final func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self.createAnimatedTransitioning(isPresenting: false)
    }
}
