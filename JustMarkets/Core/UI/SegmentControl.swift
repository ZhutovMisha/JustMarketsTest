//
//  SegmentControl.swift
//  JustMarkets
//
//  Created by Zhutov Mykhailo on 29.08.2026.
//

import UIKit
import SnapKit

private final class SegmentScrollView: UIScrollView {

    override func touchesShouldCancel(in view: UIView) -> Bool {
        view is UIButton || super.touchesShouldCancel(in: view)
    }
}

private final class SegmentButton: UIButton {

    func configure(title: String, font: UIFont) {
        setTitle(title, for: .normal)
        titleLabel?.font = font

        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    func updateColor(isSelected: Bool) {
        setTitleColor(isSelected ? Theme.Colors.primaryText : Theme.Colors.secondaryText, for: .normal)
    }
}

final class SegmentControl: BaseView {
    
    typealias OnSelect = (Int) -> Void

    private let scrollView: SegmentScrollView = {
        let view = SegmentScrollView()
        view.showsHorizontalScrollIndicator = false
        view.isDirectionalLockEnabled = true
        return view
    }()

    private let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = Theme.Spacing.extraLarge
        view.alignment = .center
        return view
    }()

    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.selectionIndicator
        return view
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.separator
        return view
    }()

    private var titles: [String] = []
    private var buttons: [SegmentButton] = []
    private var onSelect: OnSelect?

    private let feedbackGenerator = UISelectionFeedbackGenerator()

    private(set) var selectedIndex: Int = 0

    override func initialize() {
        setupUI()
        feedbackGenerator.prepare()
    }

    func configure(
        titles: [String],
        selectedIndex: Int,
        onSelect: @escaping OnSelect
    ) {
        self.titles = titles
        self.onSelect = onSelect

        self.selectedIndex = titles.indices.contains(selectedIndex)
            ? selectedIndex
            : 0

        buttons.removeAll()

        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        for (index, title) in titles.enumerated() {
            let button = makeButton(title: title, index: index)
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }

        updateColors()
        updateIndicator(animated: false)
    }

    private func handleTap(at index: Int) {
        guard
            titles.indices.contains(index),
            index != selectedIndex
        else {
            return
        }

        selectedIndex = index

        feedbackGenerator.selectionChanged()
        feedbackGenerator.prepare()

        updateColors()
        updateIndicator(animated: true)
        scrollToSelected()

        onSelect?(index)
    }

    private func setupUI() {
        addSubview(scrollView)
        addSubview(separatorView)

        scrollView.addSubview(stackView)
        scrollView.addSubview(indicatorView)

        separatorView.snp.makeConstraints { make in
            make.directionalHorizontalEdges.equalToSuperview().inset(Theme.Spacing.extraLarge)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }

        scrollView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(separatorView.snp.top)
            make.height.equalTo(scrollView.contentLayoutGuide.snp.height)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(Theme.Spacing.medium)
            make.horizontalEdges.equalTo(scrollView.contentLayoutGuide).inset(Theme.Spacing.extraLarge)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-Theme.Spacing.small)
        }
    }

    private func makeButton(title: String, index: Int) -> SegmentButton {
        let button = SegmentButton()

        button.configure(title: title, font: Theme.Fonts.segmentTitle)

        button.onTap { [weak self] in self?.handleTap(at: index) }

        return button
    }

    private func updateColors() {
        for (index, button) in buttons.enumerated() {
            button.updateColor(isSelected: index == selectedIndex)
        }
    }

    private func updateIndicator(animated: Bool) {
        guard buttons.indices.contains(selectedIndex) else {
            indicatorView.isHidden = true
            return
        }

        let button = buttons[selectedIndex]

        indicatorView.isHidden = false

        indicatorView.snp.remakeConstraints { make in
            make.directionalHorizontalEdges.equalTo(button)
            make.bottom.equalTo(scrollView.contentLayoutGuide)
            make.height.equalTo(2)
        }

        guard animated else {
            scrollView.setNeedsLayout()
            return
        }

        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            usingSpringWithDamping: 0.55,
            initialSpringVelocity: 0.6,
            options: [
                .beginFromCurrentState,
                .allowUserInteraction
            ]
        ) {
            self.scrollView.layoutIfNeeded()
        }
    }

    private func scrollToSelected() {
        guard buttons.indices.contains(selectedIndex) else {
            return
        }

        let button = buttons[selectedIndex]

        let frame = button
            .convert(button.bounds, to: scrollView)
            .insetBy(dx: -200, dy: 0)

        scrollView.scrollRectToVisible(frame, animated: true)
    }
}
