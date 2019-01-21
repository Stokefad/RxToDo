//
//  ViewController.swift
//  ToDoRx3
//
//  Created by Igor-Macbook Pro on 18/01/2019.
//  Copyright © 2019 Igor-Macbook Pro. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CoreData

class ViewController: UIViewController {

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var categoryArray = [Category]()
    
    @IBOutlet weak var countLabel: UILabel!
    
    let dBag = DisposeBag()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textbox: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = nil
        tableView.dataSource = nil
        
        retrieveCategory()
        
        driveIt()
        selectIt()
        countIt()
    }

    
    @IBAction func addCategoryPressed(_ sender: UIButton) {
        tableView.delegate = nil
        tableView.dataSource = nil
        if let text = textbox.text {
            saveCategory(name: text)
            driveIt()
        }
    }
    
    private func retrieveCategory() {
        let request : NSFetchRequest<Category> = Category.fetchRequest()
        
        do {
            categoryArray = try context.fetch(request)
        }
        catch {
            print("Error with retrieving occured \(error)")
        }
    }
    
    private func saveCategory(name : String) {
        let cat = Category(context: context)
        
        cat.name = name
        
        do {
            try context.save()
            categoryArray.append(cat)
            countIt()
        }
        catch {
            print("Error with saving occured \(error)")
        }
    }
    
    private func deleteCategoryDB(category : Category) {
        context.delete(category)
    }
    
    @objc private func deleteCategory(sender : UISwipeGestureRecognizer) {
        tableView.delegate = nil
        tableView.dataSource = nil
        
        let location = sender.location(in: tableView)
        
        if let indexPath = tableView.indexPathForRow(at: location) {
            deleteCategoryDB(category: categoryArray[indexPath.row])
            categoryArray.remove(at: indexPath.row)
            driveIt()
        }
    }
    
    private func countIt() {
        BehaviorRelay(value: categoryArray).asObservable().subscribe(onNext: { [weak self] value in
            self!.countLabel.text = String(describing: value.count)
        }).disposed(by: dBag)
    }
    
    private func driveIt() {
        BehaviorRelay(value: categoryArray)
            .asObservable()
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: "cell")) { [weak self] _, value, cell in
                cell.textLabel?.text = value.name
                let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(self!.deleteCategory(sender:)))
                rightSwipe.direction = .right
                cell.addGestureRecognizer(rightSwipe)
                self!.countIt()
        }
            .disposed(by: dBag)
    }
    
    private func selectIt() {
        tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            let destVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "todoVC") as! TodosVC
            destVC.createObservers()
            self?.navigationController?.pushViewController(destVC, animated: true)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SendCurrentCategory"), object: nil, userInfo: [
                "category" : self!.categoryArray[indexPath.row]
            ])
        }).disposed(by: dBag)
    }
}
