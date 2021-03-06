//
//  PresentationController.swift
//  ModalViewController
//
//  Created by ZJaDe on 2018/10/26.
//  Copyright © 2018 zjade. All rights reserved.
//

import UIKit

open class PresentationController: UIPresentationController {
    // MARK: -
    public class WrappingView: UIView {
        public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let view = super.hitTest(point, with: event)
            if view == self {
                return nil
            }
            return view
        }
    }
    public class DimmingView: UIView { }
    public weak var modalVC: ModalViewController?
    var modalDelegate: ModalPresentationDelegate? {
        return self.modalVC?.presentationDelegate
    }
    private weak var modalContainer: UIViewController?
    public required init(_ modalVC: ModalViewController, modalContainer: UIViewController) {
        self.modalVC = modalVC
        super.init(presentedViewController: modalVC, presenting: nil)
        self.modalContainer = modalContainer
        configInit()
    }
    public required init(_ modalVC: ModalViewController, presenting: UIViewController?) {
        self.modalVC = modalVC
        super.init(presentedViewController: modalVC, presenting: presenting)
        configInit()
    }

    open func configInit() {

    }
    private var wrappingView: WrappingView?
    private var dimmingView: DimmingView?

    open override var presentedView: UIView? {
        return self.wrappingView
    }
    // MARK: -
    public final override func presentationTransitionWillBegin() {
        self.modalDelegate?.presentationTransitionWillBegin()
        guard let presentedView = super.presentedView else { return }
        /// ZJaDe:
        let wrappingView = createWrappingView()
        self.wrappingView = wrappingView
        self.modalDelegate?.config(wrappingView: wrappingView)
        wrappingView.frame = self.frameOfPresentedViewInContainerView
        /// ZJaDe:
        presentedView.frame = wrappingView.bounds
        add(presentedView: presentedView, in: wrappingView)
        /// ZJaDe:
        let dimmingView = createDimmingView()
        self.dimmingView = dimmingView
        self.modalDelegate?.config(dimmingView: dimmingView)
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: modalVC, action: #selector(ModalViewController.dimmingViewTapped)))
        self._containerView?.addSubview(dimmingView)
        /// ZJaDe:
        showDimmingViewAnimate(dimmingView)
    }
    open override func presentationTransitionDidEnd(_ completed: Bool) {
        if completed == false {
            self.wrappingView = nil
            self.dimmingView?.removeFromSuperview()
            self.dimmingView = nil
        }
        self.modalDelegate?.presentationTransitionDidEnd(completed)
    }
    open override func dismissalTransitionWillBegin() {
        self.modalDelegate?.dismissalTransitionWillBegin()
        guard let dimmingView = dimmingView else { return }
        hideDimmingViewAnimate(dimmingView)
    }
    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed == true {
            self.wrappingView = nil
            self.dimmingView?.removeFromSuperview()
            self.dimmingView = nil
        }
        self.modalDelegate?.dismissalTransitionDidEnd(completed)
    }
    // MARK: - 自定义方法 可重写
    /// ZJaDe: 创建presentedView的 阴影层视图
    open func createWrappingView() -> WrappingView {
        let view = WrappingView()
        return view
    }
    /// ZJaDe: 创建背景层视图
    open func createDimmingView() -> DimmingView {
        let dimmingView = DimmingView()
        dimmingView.backgroundColor = UIColor.black
        dimmingView.isOpaque = false
        dimmingView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return dimmingView
    }

    /// ZJaDe: dimmingView动画
    open func showDimmingViewAnimate(_ dimmingView: DimmingView) {
        dimmingView.alpha = 0
        animate {
            dimmingView.alpha = 0.5
        }
    }
    open func hideDimmingViewAnimate(_ dimmingView: DimmingView) {
        animate {
            dimmingView.alpha = 0
        }
    }
    /// ZJaDe: add presentedView
    open func add(presentedView: UIView, in wrappingView: WrappingView) {
        wrappingView.addSubview(presentedView)
    }
    /// ZJaDe: animate
    open func animate(_ closure: @escaping () -> Void) {
        if let transitionCoordinator = self.presentingViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { (_) in
                closure()
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.35) {
                closure()
            }
        }
    }

    // MARK: - Layout
    open override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        guard container === self.modalVC else {
            return
        }
        if let containerView = self.containerView {
            containerView.setNeedsLayout()
        } else {
            containerViewWillLayoutSubviews()
            _containerView?.setNeedsLayout()
            containerViewDidLayoutSubviews()
        }
    }
    open override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        if container === self.modalVC {
            return container.preferredContentSize
        } else {
            return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }
    }

    public final override var frameOfPresentedViewInContainerView: CGRect {
        guard let modalVC = self.modalVC else {
            return super.frameOfPresentedViewInContainerView
        }
        let presentedViewContentSize = self.size(forChildContentContainer: modalVC, withParentContainerSize: containerViewBounds.size)
        guard let result = self.modalDelegate?.presentedViewFrame(containerViewBounds, presentedViewContentSize) else {
            return super.frameOfPresentedViewInContainerView
        }
        return result
    }
    open override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        updateViewsFrame()
    }
    /// ZJaDe:
    open func updateViewsFrame() {
        self.dimmingView?.frame = containerViewBounds
        self.wrappingView?.frame = self.frameOfPresentedViewInContainerView
    }

    private var _containerView: UIView? {
        let view: UIView?
        if let result = self.containerView {
            view = result
        } else if let modalContainer = self.modalContainer {
            view = modalContainer.view
        } else {
            view = nil
        }
        return view
    }
    open var containerViewBounds: CGRect {
        return _containerView?.bounds ?? CGRect.zero
    }

}
