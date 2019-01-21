//
//  TodosVC.swift
//  ToDoRx3
//
//  Created by Igor-Macbook Pro on 18/01/2019.
//  Copyright © 2019 Igor-Macbook Pro. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CoreData

class TodosVC : UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let dBag = DisposeBag()
    
    var todoArray = [Todo]()
    
    var currentCategory : Category?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textbox: UITextField!
    
    @IBOutlet weak var countLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createObservers()
        
        print(currentCategory?.name as Any)
        
        tableView.delegate = nil
        tableView.dataSource = nil
        
        retrieveCategory()

        countIt()
        driveIt()
    }
    
    
    func createObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(dealWithObserver(notification:)), name: NSNotification.Name(rawValue: "SendCurrentCategory"), object: nil)
    }
    
    @objc private func dealWithObserver(notification : NSNotification) {
        currentCategory = notification.userInfo!["category"] as? Category
        print(currentCategory?.name as Any)
    }
    
    @IBAction func addTodoPressed(_ sender: UIButton) {
        tableView.delegate = nil
        tableView.dataSource = nil
        if let text = textbox.text {
            saveTodo(text: text)
            driveIt()
        }
    }
    
    private func retrieveCategory() {
        let request : NSFetchRequest<Todo> = Todo.fetchRequest()
        var tempArr : [Todo] = [Todo]()
        
        do {
            tempArr = try context.fetch(request)
            for item in tempArr {
                if item.toCategory == currentCategory {
                    todoArray.append(item)
                }
            }
        }
        catch {
            print("Error with retrieving occured \(error)")
        }
    }
    
    private func saveTodo(text : String) {
        let todo = Todo(context: context)
        
        todo.text = text
        todo.toCategory = currentCategory
        
        do {
            try context.save()
            todoArray.append(todo)
            countIt()
        }
        catch {
            print("Error with saving occured \(error)")
        }
    }
    
    private func deleteTodo(todo : Todo) {
        context.delete(todo)
    }
    
    @objc private func swipeAction(sender : UISwipeGestureRecognizer) {
        tableView.delegate = nil
        tableView.dataSource = nil
        
        let location = sender.location(in: tableView)
        
        if let indexPath = tableView.indexPathForRow(at: location) {
            deleteTodo(todo: todoArray[indexPath.row])
            todoArray.remove(at: indexPath.row)
            countIt()
        }
    }
    
    private func countIt() {
        BehaviorRelay(value: todoArray).asObservable().subscribe(onNext: { [weak self] value in
            self!.countLabel.text = String(describing: value.count)
        }).disposed(by: dBag)
    }
    
    private func driveIt() {
        BehaviorRelay(value: todoArray)
            .asObservable()
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: "todoCell")) { [weak self] _, value, cell in
                cell.textLabel?.text = value.text
                let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(self!.swipeAction(sender:)))
                rightSwipe.direction = .right
                cell.addGestureRecognizer(rightSwipe)
            }
            .disposed(by: dBag)
    }
    
}
