import UIKit

class TaskEditorViewController: UIViewController {

    private let accentColor = UIColor(red: 0.3955705762, green: 0.2770622373, blue: 0.4479630589, alpha: 1.0)
    private let taskListPickerSpacerMinHeight: CGFloat = 28
    private let taskListPickerSpacerMaxHeight: CGFloat = 104

    let nameField = TaskNameField(frame: .zero)

    private let contentStackView = UIStackView()
    private let taskListPicker = UISegmentedControl(items: ["Today", "Backlog"])
    private let taskListPickerSpacer = UIView()

    var showsTaskListPicker: Bool {
        return false
    }

    var selectedTaskListForPicker: TaskListIds? {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureNameField()
        configureTaskListPicker()
        buildHierarchy()
        configureLayout()
        applyContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        focusNameFieldIfNeeded()
    }

    func didChangeSelectedTaskList(_ taskListId: TaskListIds) {
        // Subclasses override when they need picker updates.
    }

    func didTapSelectedTaskList(_ taskListId: TaskListIds) {
        // Subclasses override when they want tap-specific picker behavior.
    }

    func focusNameFieldIfNeeded() {
        // Subclasses can override if they don't want immediate focus on appearance.
        nameField.becomeFirstResponder()
    }

    private func configureView() {
        view.backgroundColor = .white
    }

    private func configureNameField() {
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.isScrollEnabled = true
        nameField.textAlignment = .center
        nameField.textColor = accentColor
        nameField.font = UIFont(name: "Helvetica-Bold", size: 24) ?? UIFont.boldSystemFont(ofSize: 24)
        nameField.returnKeyType = .default

        NSLayoutConstraint.activate([
            nameField.heightAnchor.constraint(equalToConstant: 140)
        ])
    }

    private func configureTaskListPicker() {
        taskListPicker.translatesAutoresizingMaskIntoConstraints = false
        taskListPicker.selectedSegmentTintColor = accentColor
        taskListPicker.setTitleTextAttributes([
            .foregroundColor: accentColor,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ], for: .normal)
        taskListPicker.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ], for: .selected)
        taskListPicker.addTarget(self, action: #selector(handleTaskListPickerChanged), for: .valueChanged)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTaskListPickerTapped(_:)))
        tapRecognizer.cancelsTouchesInView = false
        taskListPicker.addGestureRecognizer(tapRecognizer)
        taskListPicker.isHidden = !showsTaskListPicker
    }

    private func buildHierarchy() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 0
        contentStackView.alignment = .fill

        view.addSubview(contentStackView)
        contentStackView.addArrangedSubview(nameField)

        if showsTaskListPicker {
            taskListPickerSpacer.translatesAutoresizingMaskIntoConstraints = false
            contentStackView.addArrangedSubview(taskListPickerSpacer)
            contentStackView.addArrangedSubview(taskListPicker)

            NSLayoutConstraint.activate([
                taskListPickerSpacer.heightAnchor.constraint(greaterThanOrEqualToConstant: taskListPickerSpacerMinHeight),
                taskListPickerSpacer.heightAnchor.constraint(lessThanOrEqualToConstant: taskListPickerSpacerMaxHeight)
            ])

            taskListPicker.setContentHuggingPriority(.required, for: .vertical)
            taskListPicker.setContentCompressionResistancePriority(.required, for: .vertical)
        }
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 17),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor, constant: -24)
        ])
    }

    private func applyContent() {
        if let selectedTaskListForPicker {
            taskListPicker.selectedSegmentIndex = selectedTaskListForPicker == .Today ? 0 : 1
        } else {
            taskListPicker.selectedSegmentIndex = UISegmentedControl.noSegment
        }
    }

    @objc
    private func handleTaskListPickerChanged() {
        let taskListId: TaskListIds = taskListPicker.selectedSegmentIndex == 0 ? .Today : .Backlog
        didChangeSelectedTaskList(taskListId)
    }

    @objc
    private func handleTaskListPickerTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.state == .ended else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard taskListPicker.selectedSegmentIndex != UISegmentedControl.noSegment else { return }

            let taskListId: TaskListIds = taskListPicker.selectedSegmentIndex == 0 ? .Today : .Backlog
            didTapSelectedTaskList(taskListId)
        }
    }
}
