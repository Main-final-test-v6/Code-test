// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except
// as expressly permitted under the terms of the Proprietary Software License.

import CoreData
import Foundation
import UIKit

class AppsTableViewCell: UITableViewCell {
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let versionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let pillsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(versionLabel)
        contentView.addSubview(pillsStackView)
        imageView?.translatesAutoresizingMaskIntoConstraints = true

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: imageView!.trailingAnchor, constant: 15),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            versionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            versionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            versionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            versionLabel.bottomAnchor.constraint(equalTo: pillsStackView.topAnchor, constant: -10),

            pillsStackView.leadingAnchor.constraint(equalTo: imageView!.trailingAnchor, constant: 15),
            pillsStackView.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 10),
            pillsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            pillsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(with app: NSManagedObject, filePath: URL) {
        var appName = ""
        if let name = app.value(forKey: "name") as? String {
            appName += name
        }

        var description = ""
        if let version = app.value(forKey: "version") as? String {
            description += version
        }
        description += " • "
        if let bundleIdentifier = app.value(forKey: "bundleidentifier") as? String {
            description += bundleIdentifier

            if bundleIdentifier.hasSuffix("Beta") {
                appName += " (Beta)"
            }
        }

        pillsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if FileManager.default.fileExists(atPath: filePath.path) {
            if let timeToLive: Date = getValue(forKey: "timeToLive", from: app) {
                let currentDate = Date()
                let calendar = Calendar.current
                let components = calendar.dateComponents([.day], from: currentDate, to: timeToLive)

                let daysLeft = components.day ?? 0
                let expirationText = daysLeft < 0 ? "Expired" : "\(daysLeft) days left"

                let expirationPill = PillView(
                    text: expirationText,
                    backgroundColor: daysLeft < 0 ? .systemRed : .systemGreen,
                    iconName: daysLeft < 0 ? "xmark" : "timer"
                )
                pillsStackView.addArrangedSubview(expirationPill)
            }

            if app.entity.name == "SignedApps",
               let hasUpdate = app.value(forKey: "hasUpdate") as? Bool,
               hasUpdate,
               let currentVersion = app.value(forKey: "version") as? String,
               let updateVersion = app.value(forKey: "updateVersion") as? String {
                
                let updateText = "\(currentVersion) → \(updateVersion)"
                let updatePill = PillView(
                    text: updateText,
                    backgroundColor: .systemPurple,
                    iconName: "arrow.up.circle"
                )
                pillsStackView.addArrangedSubview(updatePill)
                
            } else if let teamName: String = getValue(forKey: "teamName", from: app) {
                let teamPill = PillView(
                    text: teamName,
                    backgroundColor: .systemGray,
                    iconName: "person"
                )
                pillsStackView.addArrangedSubview(teamPill)
            }
        } else {
            let deletedPill = PillView(
                text: "File Has Been Deleted",
                backgroundColor: .systemRed,
                iconName: "trash"
            )
            pillsStackView.addArrangedSubview(deletedPill)
        }

        if let osuValue: String = getValue(forKey: "oSU", from: app) {
            let osuPill = PillView(
                text: osuValue,
                backgroundColor: .systemGray,
                iconName: "questionmark.app.dashed"
            )
            pillsStackView.addArrangedSubview(osuPill)
        }

        nameLabel.text = appName
        versionLabel.text = description
    }
}

func getValue<T>(forKey key: String, from app: NSManagedObject) -> T? {
    guard let attributeType = app.entity.attributesByName[key]?.attributeType else {
        return nil
    }

    switch attributeType {
        case .stringAttributeType:
            return app.value(forKey: key) as? T
        case .dateAttributeType:
            return app.value(forKey: key) as? T
        default:
            return nil
    }
}

class BadgeView: UIView {
    private let badgeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        badgeLabel.text = "BETA"
        badgeLabel.textColor = .label
        badgeLabel.textAlignment = .center
        badgeLabel.backgroundColor = .systemYellow.withAlphaComponent(0.2)
        badgeLabel.font = .boldSystemFont(ofSize: 12)

        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeLabel)

        NSLayoutConstraint.activate([
            badgeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            badgeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            badgeLabel.widthAnchor.constraint(equalToConstant: 50),
            badgeLabel.heightAnchor.constraint(equalToConstant: 20)
        ])

        badgeLabel.layer.cornerRadius = 10
        badgeLabel.layer.cornerCurve = .continuous
        badgeLabel.clipsToBounds = true
        badgeLabel.layer.borderColor = UIColor.systemYellow.withAlphaComponent(0.3).cgColor
        badgeLabel.layer.borderWidth = 1.0
    }
}
