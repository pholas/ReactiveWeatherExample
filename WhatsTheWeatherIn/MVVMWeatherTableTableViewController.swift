//
//  WeatherTableViewController.swift
//  WhatsTheWeatherIn
//
//  Created by Marin Bencevic on 17/10/15.
//  Copyright © 2015 marinbenc. All rights reserved.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import Alamofire



class MVVMWeatherTableViewController: UITableViewController, UIAlertViewDelegate {
	
	var boundToViewModel = false
	
	func bindSourceToLabel(source: PublishSubject<String?>, label: UILabel) {
			source
				.subscribeNext { text in
						dispatch_async(dispatch_get_main_queue(), { () -> Void in
							label.text = text
						})
				}
				.addDisposableTo(disposeBag)
	}
	
	
	
	//MARK: Outlets
	
	let disposeBag = DisposeBag()
	
	@IBOutlet weak var cityTextField: UITextField!
	
	@IBOutlet weak var cityNameLabel: UILabel!
	@IBOutlet weak var cityDegreesLabel: UILabel!
	@IBOutlet weak var weatherMessageLabel: UILabel!
	@IBOutlet weak var weatherImageOutlet: UIImageView!
	@IBOutlet weak var backgroundImageOutlet: UIImageView!
	
	var alertView: UIAlertView? {
		didSet {
			if let aV = alertView {
				aV.delegate = self
				aV.show()
			}
		}
	}
	
	
	
	//table view header (current weather display)
	@IBOutlet weak var weatherView: UIView! {
		didSet {
			weatherView.bounds.size = UIScreen.mainScreen().bounds.size
		}
	}
	
	
	
	//MARK: Lifecycle
	
	var viewModel = MVVMWeatherTableViewModel()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		cityTextField.rx_text
			.debounce(0.3, scheduler: MainScheduler.sharedInstance)
			
			.subscribeNext { searchText in
				self.viewModel.searchText = searchText
			}
			.addDisposableTo(disposeBag)
		
		
		bindSourceToLabel(viewModel.cityName, label: cityNameLabel)
		bindSourceToLabel(viewModel.degrees, label: cityDegreesLabel)
		bindSourceToLabel(viewModel.weatherDescription, label: weatherMessageLabel)
		
		viewModel.weatherImage.subscribeNext { image in
			self.weatherImageOutlet.image = image
		}
		
		viewModel.tableViewData.subscribeNext { data in
			self.tableViewData = data
			self.tableView.reloadData()
		}
		
		viewModel.backgroundImage.subscribeNext { image in
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.backgroundImageOutlet.image = image
			})
		}
		
		viewModel.errorAlertView.subscribeNext { view in
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				print(view)
				self.alertView = view
			})
		}
	}
	
	
	
	//MARK: Table view data source
	
	var tableViewData:[(String, [WeatherForecast])]?
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return tableViewData == nil ? 0	: tableViewData!.count
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return tableViewData?[section].0
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tableViewData == nil ? 0 : tableViewData![section].1.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> ForecastTableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("forecastCell", forIndexPath: indexPath) as? ForecastTableViewCell
		
		cell!.forecast = tableViewData == nil ? nil : tableViewData![indexPath.section].1[indexPath.row]
		return cell!
	}
}
