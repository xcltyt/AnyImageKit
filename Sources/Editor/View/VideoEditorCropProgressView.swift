//
//  VideoEditorCropProgressView.swift
//  AnyImageKit
//
//  Created by 蒋惠 on 2019/12/19.
//  Copyright © 2019 AnyImageProject.org. All rights reserved.
//

import UIKit

protocol VideoEditorCropProgressViewDelegate: class {
    func cropProgress(_ view: VideoEditorCropProgressView, didUpdate progress: CGFloat)
}

final class VideoEditorCropProgressView: UIView {

    public weak var delegate: VideoEditorCropProgressViewDelegate?
    private let config: ImageEditorController.VideoConfig
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        return view
    }()
    private lazy var progressContentView: UIView = {
        let view = UIView()
        let pan = UIPanGestureRecognizer(target: self, action: #selector(progressViewPan(_:)))
        view.addGestureRecognizer(pan)
        return view
    }()
    private lazy var progressView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2.5
        view.backgroundColor = UIColor.white
        return view
    }()
    private(set) lazy var leftButton: UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(BundleHelper.image(named: "VideoCropLeftWhite"), for: .normal)
        view.setImage(BundleHelper.image(named: "VideoCropLeftBlack"), for: .selected)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(leftButtonPan(_:)))
        view.addGestureRecognizer(pan)
        return view
    }()
    private(set) lazy var rightButton: UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(BundleHelper.image(named: "VideoCropRightWhite"), for: .normal)
        view.setImage(BundleHelper.image(named: "VideoCropRightBlack"), for: .selected)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(rightButtonPan(_:)))
        view.addGestureRecognizer(pan)
        return view
    }()
    private lazy var contentLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.isHidden = true
        layer.frame = bounds
        layer.fillRule = .evenOdd
        layer.fillColor = config.tintColor.cgColor
        return layer
    }()
    private lazy var darkLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.frame = bounds
        layer.fillRule = .evenOdd
        layer.fillColor = UIColor.black.withAlphaComponent(0.6).cgColor
        return layer
    }()
    
    private(set) var left: CGFloat = 0
    private(set) var right: CGFloat = 1
    
    public var progress: CGFloat {
        let x = contentView.frame.origin.x + progressView.frame.origin.x
        return x / (bounds.width - 20)
    }
    
    /// 预览图
    private var previews: [UIImageView] = []
    
    init(frame: CGRect, config: ImageEditorController.VideoConfig) {
        self.config = config
        super.init(frame: frame)
        layer.cornerRadius = 5
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    private func setupView() {
        layer.addSublayer(darkLayer)
        contentView.layer.addSublayer(contentLayer)
        
        addSubview(contentView)
        addSubview(progressContentView)
        contentView.addSubview(leftButton)
        contentView.addSubview(rightButton)
        progressContentView.addSubview(progressView)
        
        contentView.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
        }
        leftButton.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalToSuperview()
            maker.width.equalTo(20)
        }
        rightButton.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.right.equalToSuperview()
            maker.width.equalTo(20)
        }
        progressContentView.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalTo(leftButton.snp.right)
            maker.right.equalTo(rightButton.snp.left)
        }
        progressView.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview().inset(3)
            maker.width.equalTo(5)
            maker.left.equalToSuperview()
        }
    }
    
    private func layout() {
        let isSelected = right - left != 1
        leftButton.isSelected = isSelected
        rightButton.isSelected = isSelected
        contentLayer.isHidden = !isSelected
        
        contentView.snp.updateConstraints { (maker) in
            maker.left.equalToSuperview().offset(left*bounds.width)
            maker.right.equalToSuperview().offset(-((1-right)*(bounds.width)))
        }
        progressView.snp.updateConstraints { (maker) in
            maker.left.equalToSuperview()
        }
        contentLayer.frame = contentView.bounds
        updateContentLayer()
        updateDarkLayer()
    }
    
    private func updateContentLayer() {
        let contentPath = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 5)
        var rect = contentView.bounds
        rect.origin.x += 20
        rect.origin.y += 5
        rect.size.width -= 40
        rect.size.height -= 10
        let rectPath = UIBezierPath(rect: rect)
        contentPath.append(rectPath)
        contentLayer.path = contentPath.cgPath
    }
    
    private func updateDarkLayer() {
        let darkPath = UIBezierPath(rect: bounds)
        let rectPath = UIBezierPath(rect: contentView.frame)
        darkPath.append(rectPath)
        darkLayer.path = darkPath.cgPath
    }
}

// MARK: - Public
extension VideoEditorCropProgressView {
    
    public func setupProgressImages(_ count: Int, image: UIImage?) {
        previews = (0..<count).map{ _ in UIImageView(image: image) }
        let stackView = UIStackView(arrangedSubviews: previews)
        stackView.spacing = 0
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        insertSubview(stackView, at: 0)
        stackView.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview().inset(5)
            maker.left.right.equalToSuperview().inset(20)
        }
    }
    
    public func setProgressImage(_ image: UIImage, idx: Int) {
        guard idx < previews.count else { return }
        self.previews[idx].setImage(image, animated: true)
    }
    
    public func setProgress(_ progress: CGFloat) {
        var progress = progress < 0 ? 0 : (progress > 1 ? 1 : progress)
        progress = progress < left ? left : (progress > right ? right : progress)
        let offset = (progress - left) / (right - left) * (progressContentView.frame.width - progressView.frame.width)
        progressView.snp.updateConstraints { (maker) in
            maker.left.equalToSuperview().offset(offset)
        }
    }
}

// MARK: - Target
extension VideoEditorCropProgressView {
    
    @objc private func progressViewPan(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: self)
        let progress = point.x / bounds.width
        setProgress(progress)
        if progress < left || progress > right {
            return
        }
        delegate?.cropProgress(self, didUpdate: progress)
    }
    
    @objc private func leftButtonPan(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: self)
        let x = point.x < 0 ? 0 : point.x
        let tmpLeft = x / bounds.width
        if right - tmpLeft < 0.2 {
            return
        }
        left = tmpLeft
        layout()
        delegate?.cropProgress(self, didUpdate: left)
    }
    
    @objc private func rightButtonPan(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: self)
        let x = point.x > bounds.width ? bounds.width : point.x
        let tmpRight = x / bounds.width
        if tmpRight - left < 0.2 {
            return
        }
        right = tmpRight
        layout()
        delegate?.cropProgress(self, didUpdate: right)
    }
}