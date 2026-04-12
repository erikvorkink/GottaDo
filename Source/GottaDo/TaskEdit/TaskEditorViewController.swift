import UIKit

class TaskEditorViewController: UIViewController {

    private let accentColor = UIColor(red: 0.3955705762, green: 0.2770622373, blue: 0.4479630589, alpha: 1.0)

    let nameField = TaskNameField(frame: .zero)

    private let contentStackView = UIStackView()
    private let taskListPicker = UISegmentedControl(items: ["Today", "Backlog"])

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

    func didChangeSelectedTaskList(_ taskListId: TaskListIds) {
        // Subclasses override when they need picker updates.
    }

    private func configureView() {
        view.backgroundColor = .white
    }

    private func configureNameField() {
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.textAlignment = .center
        nameField.textColor = accentColor
        nameField.font = UIFont(name: "Helvetica-Bold", size: 24) ?? UIFont.boldSystemFont(ofSize: 24)
        nameField.clearButtonMode = .whileEditing

        NSLayoutConstraint.activate([
            nameField.heightAnchor.constraint(equalToConstant: 60)
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
        taskListPicker.isHidden = !showsTaskListPicker
    }

    private func buildHierarchy() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 18
        contentStackView.alignment = .fill

        view.addSubview(contentStackView)
        contentStackView.addArrangedSubview(nameField)

        if showsTaskListPicker {
            contentStackView.addArrangedSubview(taskListPicker)
        }
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
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
}
