//
//  OperatorTableViewController.swift
//  RxMarbles
//
//  Created by Roman Tutubalin on 09.01.16.
//  Copyright © 2016 AnjLab. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct Section {
    var name: String
    var rows: [Operator]
}

class OperatorsTableViewController: UITableViewController, UISearchResultsUpdating {
    private let _disposeBag = DisposeBag()

    var selectedOperator: Operator = Operator.CombineLatest {
        didSet {
            tableView.reloadData()
        }
    }
    
    private let _searchController = UISearchController(searchResultsController: nil)
    private var _filteredSections = [Section]()
    
    private let _sections = [
        Section(
            name: "Combining",
            rows: [.CombineLatest, .Concat, .Merge, .StartWith, .SwitchLatest, .WithLatestFrom, .Zip]
        ),
        Section(
            name: "Conditional",
            rows: [.Amb, .SkipUntil, .SkipWhile, .SkipWhileWithIndex, .TakeUntil, .TakeWhile, .TakeWhileWithIndex]
        ),
        Section(
            name: "Creating",
            rows: [.Empty, .Interval, .Just, .Never, .Of, .RepeatElement, .Throw, .Timer]
        ),
        Section(
            name: "Error",
            rows: [.CatchError, .CatchErrorJustReturn, .Retry]
        ),
        Section(
            name: "Filtering",
            rows: [.Debounce, .DistinctUntilChanged, .ElementAt, .Filter, .IgnoreElements, .Sample, .Single, .Skip, .SkipDuration, .Take, .TakeDuration, .TakeLast, .Throttle]
        ),
        Section(
            name: "Mathematical",
            rows: [.Reduce]
        ),
        Section(
            name: "Transforming",
            rows: [.Buffer, .DelaySubscription, .FlatMap, .FlatMapFirst, .FlatMapLatest, .Map, .MapWithIndex, .Scan, .ToArray]
        ),
        Section(
            name: "Utility",
            rows: [.Timeout]
        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Operators"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Help", style: .Plain, target: self, action: #selector(OperatorsTableViewController.openHelpView))
        
        _searchController.searchResultsUpdater = self
        _searchController.dimsBackgroundDuringPresentation = false
        _searchController.searchBar.searchBarStyle = .Minimal
       
        definesPresentationContext = true
        
        tableView.tableHeaderView = _searchController.searchBar
        tableView.tableFooterView = UIView()
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "OperatorCell")
        
        tableView
            .rx_itemSelected
            .map(_rowAtIndexPath)
            .subscribeNext { [unowned self] op in self.openOperator(op)
            }
            .addDisposableTo(_disposeBag)
        
        // Check for force touch feature, and add force touch/previewing capability.
        if traitCollection.forceTouchCapability == .Available {
            /*  
                Register for `UIViewControllerPreviewingDelegate` to enable
                "Peek" and "Pop".
                (see: MasterViewController+UIViewControllerPreviewing.swift)

                The view controller will be automatically unregistered when it is
                deallocated.
            */
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
    }
    
    func openOperator(op: Operator) {
        selectedOperator = op
        let viewController = OperatorViewController(rxOperator: selectedOperator)
        showDetailViewController(viewController, sender: nil)
    }
    
    func openHelpView() {
        let helpController = HelpViewController()
        presentViewController(helpController, animated: true, completion: nil)
    }

    // MARK: - Table view data source
    
    private var _activeSections: [Section] {
        get { return isSearchActive() ? _filteredSections : _sections }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return _activeSections.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sec = _activeSections[section]
        return sec.name
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _activeSections[section].rows.count
    }
    
    private func _rowAtIndexPath(indexPath: NSIndexPath) -> Operator {
        let section = _activeSections[indexPath.section]
        return section.rows[indexPath.row]
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let op = _rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier("OperatorCell", forIndexPath: indexPath)
        
        cell.textLabel?.text = op.description
        cell.accessoryType = op == selectedOperator ? .Checkmark : .None

        return cell
    }
    
//    MARK: - Filtering Sections
    
    private func filterSectionsWithText(text: String) {
        _filteredSections.removeAll()
        _sections.forEach({ section in
            let results = section.rows.filter({ row in
                row.description.lowercaseString.containsString(text.lowercaseString)
            })
            if results.count > 0 {
                _filteredSections.append(Section(name: section.name, rows: results))
            }
        })
    }
    
//    MARK: - UISearchResultsUpdating
    
    func isSearchActive() -> Bool {
        return _searchController.active && _searchController.searchBar.text != ""
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let searchString = searchController.searchBar.text {
            filterSectionsWithText(searchString)
        }
        tableView.reloadData()
    }
    
    func focusSearch() {
        presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
        _searchController.searchBar.becomeFirstResponder()
    }
    
//    MARK: UIContentContainer
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        _searchController.active = false
    }
}

extension OperatorsTableViewController: UIViewControllerPreviewingDelegate {
    /// Create a previewing view controller to be shown at "Peek".
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed.
        guard let indexPath = tableView.indexPathForRowAtPoint(location),
                  cell = tableView.cellForRowAtIndexPath(indexPath)
        else { return nil }
        
        selectedOperator = _rowAtIndexPath(indexPath)
        
        // Create a detail view controller and set its properties.
        let detailController = OperatorViewController(rxOperator:selectedOperator)
        
        // Set the source rect to the cell frame, so surrounding elements are blurred.
        previewingContext.sourceRect = cell.frame
        
        return detailController
    }
    
    /// Present the view controller for the "Pop" action.
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        // Reuse the "Peek" view controller for presentation.
        showDetailViewController(viewControllerToCommit, sender: self)
    }
}
