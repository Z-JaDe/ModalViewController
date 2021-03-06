//
//  ModalAnimatedTransitioningDelegate.swift
//  ModalViewController
//
//  Created by ZJaDe on 2018/10/27.
//  Copyright © 2018 zjade. All rights reserved.
//

import UIKit

public protocol ModalAnimatedTransitioningDeledate: AnyObject {
    /// ZJaDe: 呈现toView时 的最初frame
    func calculateToViewInitialFrame(finalFrame: CGRect) -> CGRect
    /// ZJaDe: 隐藏fromView时 的最终frame
    func calculateFromViewFinalFrame(initialFrame: CGRect) -> CGRect
}
