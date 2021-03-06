//
//  EditorEditOptionsView.swift
//  AnyImageKit
//
//  Created by 蒋惠 on 2019/10/24.
//  Copyright © 2019 AnyImageProject.org. All rights reserved.
//

import UIKit

protocol EditorEditOptionsViewDelegate: class {
    
    func editOptionsView(_ editOptionsView: EditorEditOptionsView, optionDidChange option: EditorPhotoToolOption?)
}

final class EditorEditOptionsView: UIView {
    
    weak var delegate: EditorEditOptionsViewDelegate?
    
    private(set) var currentOption: EditorPhotoToolOption?
    
    private let options: EditorPhotoOptionsInfo
    private var buttons: [UIButton] = []
    private let spacing: CGFloat = 25
    
    init(frame: CGRect, options: EditorPhotoOptionsInfo) {
        self.options = options
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        for (idx, option) in options.toolOptions.enumerated() {
            let button = createButton(tag: idx, option: option)
            buttons.append(button)
        }
        
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.spacing = spacing
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        addSubview(stackView)
        stackView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.height.equalTo(25)
        }
        buttons.forEach {
            $0.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(stackView.snp.height)
            }
        }
    }
    
    private func createButton(tag: Int, option: EditorPhotoToolOption) -> UIButton {
        let button = UIButton(type: .custom)
        let image = BundleHelper.image(named: option.imageName)?.withRenderingMode(.alwaysTemplate)
        button.tag = tag
        button.setImage(image, for: .normal)
        button.imageView?.tintColor = .white
        button.accessibilityLabel = BundleHelper.editorLocalizedString(key: option.description)
        return button
    }
    
    private func selectButton(_ button: UIButton) {
        currentOption = options.toolOptions[button.tag]
        for btn in buttons {
            let isSelected = btn == button
            btn.isSelected = isSelected
            btn.imageView?.tintColor = isSelected ? options.tintColor : .white
        }
    }
}

// MARK: - Public function
extension EditorEditOptionsView {
    
    func unselectButtons() {
        self.currentOption = nil
        for button in buttons {
            button.isSelected = false
            button.imageView?.tintColor = .white
        }
    }
}

// MARK: - ResponseTouch
extension EditorEditOptionsView: ResponseTouch {
    
    @discardableResult
    func responseTouch(_ point: CGPoint) -> Bool {
        for (idx, button) in buttons.enumerated() {
            let frame = button.frame.bigger(.init(top: spacing/4, left: spacing/2, bottom: spacing*0.8, right: spacing/2))
            if frame.contains(point) { // inside
                if let current = currentOption, options.toolOptions[idx] == current {
                    unselectButtons()
                } else {
                    selectButton(button)
                }
                delegate?.editOptionsView(self, optionDidChange: self.currentOption)
                return true
            }
        }
        return false
    }
}
