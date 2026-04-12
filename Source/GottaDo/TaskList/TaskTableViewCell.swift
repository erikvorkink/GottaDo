import UIKit

final class TaskTableViewCell: UITableViewCell {
    static let reuseIdentifier = "TaskCell"

    private let titleFont = UIFont(name: "Helvetica", size: 20) ?? UIFont.systemFont(ofSize: 20)
    private let oldTaskBadgeText = "💀"

    private let taskLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let oldTaskBadgeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = "💀"
        label.isHidden = true
        return label
    }()

    private let flagImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.isHidden = true
        return imageView
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [taskLabel, oldTaskBadgeLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .firstBaseline
        stackView.spacing = 8
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        taskLabel.attributedText = nil
        oldTaskBadgeLabel.isHidden = true
        flagImageView.image = nil
        flagImageView.isHidden = true
    }

    func configure(with task: Task, isOldTask: Bool) {
        taskLabel.attributedText = makeAttributedTitle(for: task)
        taskLabel.textColor = UIColor(white: task.completed ? 0.7 : 0.2, alpha: 1.0)

        oldTaskBadgeLabel.text = oldTaskBadgeText
        oldTaskBadgeLabel.isHidden = !isOldTask

        if task.flagged {
            let flagImageName = task.completed ? "flagged-faded" : "flagged"
            flagImageView.image = UIImage(named: flagImageName)
            flagImageView.isHidden = false
        } else {
            flagImageView.image = nil
            flagImageView.isHidden = true
        }
    }

    private func configureLayout() {
        selectionStyle = .default
        accessoryType = .none

        contentView.addSubview(textStackView)
        contentView.addSubview(flagImageView)

        NSLayoutConstraint.activate([
            textStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            flagImageView.leadingAnchor.constraint(equalTo: textStackView.trailingAnchor, constant: 12),
            flagImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            flagImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            flagImageView.widthAnchor.constraint(equalToConstant: 22),
            flagImageView.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    private func makeAttributedTitle(for task: Task) -> NSAttributedString {
        let title = task.name ?? ""
        let attributes: [NSAttributedString.Key: Any] = [
            .font: titleFont
        ]
        let attributedTitle = NSMutableAttributedString(string: title, attributes: attributes)

        if task.completed {
            attributedTitle.addAttribute(.strikethroughStyle, value: 2, range: NSRange(location: 0, length: attributedTitle.length))
        }

        return attributedTitle
    }
}
