import UIKit
import CoreData

class TaskListViewController: UIViewController {
    private let oldTaskBadgeText = "💀"

    private enum StoryboardIdentifier {
        static let taskAddNavigationController = "TaskAddNavigationController"
        static let taskEditNavigationController = "TaskEditNavigationController"
    }

    private let titleColor = UIColor(red: 0.3510695994, green: 0.2219223082, blue: 0.4083004892, alpha: 1.0)
    private let utilityButtonTintColor = UIColor(red: 0.3955705762, green: 0.2770622373, blue: 0.4479630589, alpha: 1.0)
    private let floatingButtonShadowColor = UIColor.black.withAlphaComponent(0.14)
    private let headerTopPadding: CGFloat = 14
    private let headerBottomPadding: CGFloat = 10
    private let tableBottomInset: CGFloat = 92

    @IBOutlet weak var tableView: UITableView!
    var currentTaskListId = TaskListIds.Today
    var tasks: [NSManagedObject] = []

    var listTitle: String {
        return "Tasks"
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = titleColor
        label.font = UIFont(name: "HelveticaNeue-Bold", size: 30) ?? UIFont.boldSystemFont(ofSize: 30)
        label.adjustsFontForContentSizeCategory = true
        label.text = listTitle
        return label
    }()

    private lazy var clearButton: UIButton = makeUtilityButton(
        imageName: "clear",
        accessibilityLabel: "Clear completed tasks",
        action: #selector(clear(_:))
    )

    private lazy var reorderButton: UIButton = makeUtilityButton(
        imageName: "reorder",
        accessibilityLabel: "Reorder tasks",
        action: #selector(toggleReorder(_:))
    )

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "add"), for: .normal)
        button.addTarget(self, action: #selector(showTaskAddModal), for: .touchUpInside)
        button.accessibilityLabel = "Add task"
        button.layer.shadowColor = floatingButtonShadowColor.cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 10
        button.layer.shadowOffset = CGSize(width: 0, height: 5)
        return button
    }()

    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    private lazy var actionsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [clearButton, reorderButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureLayout()
        configureTableView()
        configureGestureRecognizers()
        configureObservers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addButton.layer.shadowPath = UIBezierPath(ovalIn: addButton.bounds).cgPath
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    // Get out of reorder mode when switching away
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopReorder()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureLayout() {
        view.backgroundColor = .white
        titleLabel.text = listTitle

        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(actionsStackView)
        view.addSubview(addButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: headerTopPadding),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -headerBottomPadding),

            actionsStackView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            actionsStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            actionsStackView.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12),

            addButton.widthAnchor.constraint(equalToConstant: 60),
            addButton.heightAnchor.constraint(equalToConstant: 60),
            addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -14),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])

        let tableConstraints = view.constraints.filter { constraint in
            constraint.firstItem as AnyObject? === tableView || constraint.secondItem as AnyObject? === tableView
        }
        NSLayoutConstraint.deactivate(tableConstraints)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        tableView.contentInset.bottom = tableBottomInset
        tableView.verticalScrollIndicatorInsets.bottom = tableBottomInset
    }

    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.contentInsetAdjustmentBehavior = .never
    }

    private func configureGestureRecognizers() {
        let tableLongPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleTableLongPress))
        self.tableView.addGestureRecognizer(tableLongPressRecognizer)

        let reorderButtonLongPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleReorderButtonLongPress))
        self.reorderButton.addGestureRecognizer(reorderButtonLongPressRecognizer)
    }

    private func configureObservers() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        notificationCenter.addObserver(self, selector: #selector(refresh), name: NSNotification.Name("taskCreatedByModal"), object: nil)
        notificationCenter.addObserver(self, selector: #selector(refresh), name: NSNotification.Name("taskEditedByModal"), object: nil)
        notificationCenter.addObserver(self, selector: #selector(refresh), name: NSNotification.Name("taskDeletedByModal"), object: nil)
        notificationCenter.addObserver(self, selector: #selector(refresh), name: NSNotification.Name("bulkTasksDeleted"), object: nil)
    }
    
    // Get out of reorder mode when moving app to background
    @objc func appMovedToBackground() {
        stopReorder()
    }

    @objc private func showTaskAddModal() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let navigationController = storyboard.instantiateViewController(withIdentifier: StoryboardIdentifier.taskAddNavigationController) as? UINavigationController else {
            alert("Unable to open add task")
            return
        }

        if let viewController = navigationController.topViewController as? TaskAddViewController {
            viewController.newTaskTaskListId = currentTaskListId
        }

        present(navigationController, animated: true)
    }

    func alert(_ title: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func handleTableLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = longPressGestureRecognizer.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                // Flag/unflag task
                if let task = tasks[indexPath.row] as? Task {
                    if toggleTaskFlagged(task) {
                        refresh()
                    }
                }
            }
        }
    }
    
    @objc func handleReorderButtonLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            HapticHelper.generateSmallFeedback()
            smartSortTasks()
            refreshTasks()
            stopReorder()
        }
    }
    
    // Remove completed tasks from list
    @IBAction func clear(_ sender: Any) {
        if removeCompleted() {
            HapticHelper.generateSmallFeedback()
            refreshTasks()
        }
    }
    
    // Toggle reorder mode
    @IBAction func toggleReorder(_ sender: Any) {
        HapticHelper.generateSmallFeedback()
        if tableView.isEditing {
            stopReorder()
        } else {
            startReorder()
        }
    }
    
    @objc func refresh() {
        refreshTasks()
        refreshBadge()
    }
    
    func refreshTasks() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        tasks.removeAll()
        tasks = appDelegate.getManagedContext().getVisibleTasks(in: currentTaskListId)
        tableView.reloadData()

        if tasks.count > 0 {
            handlePopulatedTaskList()
        } else {
            handleEmptyTaskList()
        }
    }
    
    func handlePopulatedTaskList() {
        hideBlankState()
        clearButton.isHidden = !listContainsCompletedTasks()
        reorderButton.isHidden = tasks.count < 2
    }
    
    func handleEmptyTaskList() {
        showBlankState("Nothing to do")
        clearButton.isHidden = true
        reorderButton.isHidden = true
    }
    
    func listContainsCompletedTasks() -> Bool {
        for task in tasks as! [Task] {
            if task.completed {
                return true
            }
        }
        return false
    }
    
    func refreshBadge() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.setBadgeNumber(getOutstandingTodayTaskCount())
    }
    
    func getOutstandingTodayTaskCount() -> Int {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return 0 }
        return appDelegate.getManagedContext().getOutstandingVisibleTaskCount(in: TaskListIds.Today)
    }
    
    // Move from Today <--> Backlog
    func moveTask(_ task: Task) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        
        let moveToTaskListId = currentTaskListId.rawValue == TaskListIds.Backlog.rawValue ? TaskListIds.Today : TaskListIds.Backlog
        
        if moveToTaskListId == TaskListIds.Today {
            // Backlog -> Today = bottom of list
            task.setPosition(1 + appDelegate.getManagedContext().getHighestVisibleTaskPosition(in: moveToTaskListId))
        } else {
            // Today -> Backlog = top of list
            incrementPositionOfVisibleTasksInGivenList(moveToTaskListId)
            task.setPosition(1)
        }
        
        task.setTaskListId(moveToTaskListId) // wait until position has been determined
        
        do {
            try appDelegate.saveContext()
        } catch {
            alert("Unable to move task")
            return false
        }
        HapticHelper.generateSmallFeedback()
        return true
    }
    
    // Used to insert a Today -> Backlog task at the top of the list
    func incrementPositionOfVisibleTasksInGivenList(_ taskListId: TaskListIds) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let tasks = appDelegate.getManagedContext().getVisibleTasks(in: taskListId)
        for task in tasks as! [Task] {
            task.setPosition(1 + Int(task.position))
        }
    }
    
    func toggleTaskFlagged(_ task: Task) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        
        task.toggleFlagged()
        do {
            try appDelegate.saveContext()
        } catch {
            alert("Unable to toggle flagged")
            return false
        }
        HapticHelper.generateSmallFeedback()
        return true
    }
    
    func toggleTaskComplete(_ task: Task) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }

        if task.completed {
            task.uncomplete()
        } else {
            task.complete()
        }
        do {
            try appDelegate.saveContext()
        } catch {
            alert("Unable to toggle completed")
            return false
        }
        HapticHelper.generateBigFeedback()
        return true
    }
    
    // Sort completed then flagged then unflagged
    func smartSortTasks() {
        var completedTasks = [NSManagedObject]()
        var flaggedTasks = [NSManagedObject]()
        var unflaggedTasks = [NSManagedObject]()
        
        for task in tasks as! [Task] {
            if task.completed {
                completedTasks.append(task)
            } else if task.flagged {
                flaggedTasks.append(task)
            } else {
                unflaggedTasks.append(task)
            }
        }
        
        var nextPosition = 1
        for task in completedTasks as! [Task] {
            task.setPosition(nextPosition)
            nextPosition += 1
        }
        for task in flaggedTasks as! [Task] {
            task.setPosition(nextPosition)
            nextPosition += 1
        }
        for task in unflaggedTasks as! [Task] {
            task.setPosition(nextPosition)
            nextPosition += 1
        }
    }
    
    func removeCompleted() -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        
        let tasksToRemove = appDelegate.getManagedContext().getCompletedVisibleTasks(in: currentTaskListId)
        for task in tasksToRemove as! [Task] {
            task.remove()
        }
        do {
            try appDelegate.saveContext()
        } catch {
            alert("Unable to remove completed tasks")
            return false
        }
        HapticHelper.generateBigFeedback()
        return true
    }
    
    func startReorder() {
        tableView.isEditing = true
        reorderButton.setImage(UIImage(named: "reorder-active"), for: .normal)
        addButton.isHidden = true
    }
    
    func stopReorder() {
        tableView.isEditing = false
        reorderButton.setImage(UIImage(named: "reorder"), for: .normal)
        addButton.isHidden = false
    }

    private func makeUtilityButton(imageName: String, accessibilityLabel: String, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: imageName), for: .normal)
        button.tintColor = utilityButtonTintColor
        button.accessibilityLabel = accessibilityLabel
        button.addTarget(self, action: action, for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 40),
            button.heightAnchor.constraint(equalToConstant: 40)
        ])
        return button
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController: UITableViewDataSource {
    
    // Row for each task
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    // Render task row
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        if let task = tasks[indexPath.row] as? Task {
            cell.textLabel?.font = UIFont.init(name: "Helvetica", size: 20)
            cell.textLabel?.textColor = UIColor(white: task.completed ? 0.7 : 0.2, alpha: 1.0) // lighter gray once completed
            cell.textLabel?.attributedText = getCellAttributedText(task);
            cell.textLabel?.numberOfLines = 0 // activate text wrapping
            
            if task.flagged {
                let flagImageName = task.completed ? "flagged-faded" : "flagged"
                let flagImage = UIImageView(image: UIImage(named: flagImageName))
                cell.accessoryView = flagImage
            } else {
                cell.accessoryView = .none
            }
        }
        return cell
    }
    
    func getCellAttributedText(_ task: Task) -> NSMutableAttributedString {
        let name = task.name ?? ""
        let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: name)
        if task.completed {
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
        }
        if isOldTask(task) {
            let spacerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Helvetica", size: 20) ?? UIFont.systemFont(ofSize: 20)
            ]
            let badgeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .baselineOffset: 1
            ]
            attributeString.append(NSAttributedString(string: "  ", attributes: spacerAttributes))
            attributeString.append(NSAttributedString(string: oldTaskBadgeText, attributes: badgeAttributes))
        }
        return attributeString
    }
    
    func isOldTask(_ task: Task) -> Bool {
        guard let createdDate = task.createdDate,
              let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) else {
            return false
        }
        return createdDate < sixMonthsAgo
    }
    
    // No delete icon when reordering
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none;
    }
    
    // No indent when reordering
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    // All rows can be reordered
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Persist a reordered task
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let taskToReorder = tasks[sourceIndexPath.row]
        tasks.remove(at: sourceIndexPath.row)
        tasks.insert(taskToReorder, at: destinationIndexPath.row)
        
        syncTaskPositionsToOrderInArray()
        do {
            try appDelegate.saveContext()
        } catch {
            alert("Unable to save new order")
        }
    }
    
    // Set the position value of each task so that it matches the current position in the tasks array
    func syncTaskPositionsToOrderInArray() {
        var nextPosition = 1
        for task in tasks as! [Task] {
            task.setPosition(nextPosition)
            nextPosition += 1
        }
    }
}

// MARK: - UITableViewDelegate
extension TaskListViewController: UITableViewDelegate {
    
    func showBlankState(_ message: String) {
        let emptyView = UIView(frame: tableView.bounds)
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.textColor = UIColor.lightGray
        messageLabel.font = UIFont(name: "Helvetica", size: 20)
        emptyView.addSubview(messageLabel)
        messageLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor).isActive = true
        messageLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        messageLabel.leftAnchor.constraint(equalTo: emptyView.leftAnchor, constant: 20).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: emptyView.rightAnchor, constant: -20).isActive = true
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        tableView.backgroundView = emptyView
        tableView.separatorStyle = .none
    }
    
    func hideBlankState() {
        tableView.backgroundView = nil
        tableView.separatorStyle = .singleLine
    }
    
    // Selecting task opens up the edit view
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let task = tasks[indexPath.row] as? Task {
            showTaskEditModal(for: task)
        }
    }
    
    // Swipe right to complete/uncomplete
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let task = self.tasks[indexPath.row] as? Task {
            let title = (task.completed) ? "Restore" : "Complete"
            let action = UIContextualAction(style: .normal, title: title) { (action, view, handler) in
                if self.toggleTaskComplete(task) {
                    self.refresh()
                }
            }
            action.backgroundColor = UIColor(red: 0.25, green: 0.38, blue: 0.25, alpha: 1.0)
            let configuration = UISwipeActionsConfiguration(actions: [action])
            configuration.performsFirstActionWithFullSwipe = true
            return configuration
        }
        return UISwipeActionsConfiguration()
    }
    
    // Swipe left to move between Today and Backlog
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let task = self.tasks[indexPath.row] as? Task {
            let title = (currentTaskListId == TaskListIds.Today) ? "Backlog" : "Today"
            let moveTaskAction = UIContextualAction(style: .normal, title: title) { (action, view, handler) in
                if self.moveTask(task) {
                    self.refresh()
                }
            }
            moveTaskAction.backgroundColor = UIColor(red: 0.33, green: 0.19, blue: 0.38, alpha: 1.0)
            let configuration = UISwipeActionsConfiguration(actions: [moveTaskAction])
            configuration.performsFirstActionWithFullSwipe = true
            return configuration
        }
        return UISwipeActionsConfiguration()
    }
    
    private func showTaskEditModal(for task: Task) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let navigationController = storyboard.instantiateViewController(withIdentifier: StoryboardIdentifier.taskEditNavigationController) as? UINavigationController else {
            alert("Unable to open task")
            return
        }

        if let viewController = navigationController.topViewController as? TaskEditViewController {
            viewController.task = task
        }

        present(navigationController, animated: true)
    }
}
