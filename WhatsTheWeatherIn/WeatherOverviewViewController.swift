//
//  WeatherTableViewController.swift
//  WhatsTheWeatherIn
//
//  Created by Marin Bencevic on 17/10/15.
//  Copyright © 2015 marinbenc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


//MARK: - ForecastModel

///Represents a presentation layer model for a Forecast, to be displayed in a UITableViewCell
struct ForecastModel {
    let time: String
    let description: String
    let temp: String
}


//MARK: -
//MARK: - WeatherOverviewViewController
final class WeatherOverviewViewController: UIViewController {
    
    
    //MARK: - Dependencies
    
    fileprivate var viewModel: WeatherViewModel!
    fileprivate let disposeBag = DisposeBag()
    
    
	//MARK: - Outlets
    
    @IBOutlet weak var forecastsTableView: UITableView!
    
	@IBOutlet weak var cityTextField: UITextField!
	
    @IBOutlet weak var cityNameLabel: UILabel!
	@IBOutlet weak var cityDegreesLabel: UILabel!
	@IBOutlet weak var weatherMessageLabel: UILabel!
    
    @IBOutlet weak var weatherIconImageView: UIImageView!
    @IBOutlet weak var weatherBackgroundImageView: UIImageView!
    
    ///table view header (current weather display)
    @IBOutlet weak var weatherView: UIView!
	
	//MARK: - Lifecycle
    
    fileprivate func addBindsToViewModel(_ viewModel: WeatherViewModel) {
        
        viewModel.searchText.asObservable()
            .bindTo(cityTextField.rx.text)
            .addDisposableTo(disposeBag)

        viewModel.cityName
            .bindTo(cityNameLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        viewModel.temp
            .bindTo(cityDegreesLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        viewModel.weatherDescription
            .bindTo(weatherMessageLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        viewModel.weatherImageData
            .map(UIImage.init)
            .bindTo(weatherIconImageView.rx.image)
            .addDisposableTo(disposeBag)
        
        viewModel.weatherBackgroundImage
            .map { $0.image }
            .bindTo(weatherBackgroundImageView.rx.image)
            .addDisposableTo(disposeBag)
        
        viewModel.cellData
            .bindTo(forecastsTableView.rx.items(dataSource: self))
            .addDisposableTo(disposeBag)
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()
        
        forecastsTableView.delegate = self
        
        viewModel = WeatherViewModel(weatherService: WeatherAPIService())
		addBindsToViewModel(viewModel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //Set Forecast views hight to cover the whole screen

        forecastsTableView.tableHeaderView?.bounds.size.height = view.bounds.height
        //A dirty UIKit bug workaround to force a UI update on the TableView's header
        forecastsTableView.tableHeaderView = forecastsTableView.tableHeaderView
    }
    
    //MARK: - TableViewData
    
    //The data to update the tableView with. These is a better way to update the
    //tableView with RxSwift, please see 
    //https://github.com/ReactiveX/RxSwift/tree/master/RxExample
    //However this implementation is much simpler
    fileprivate var tableViewData: [(day: String, forecasts: [ForecastModel])]? {
        didSet {
            forecastsTableView.reloadData()
        }
    }
}


//MARK: - Table View Data Source & Delegate
extension WeatherOverviewViewController: UITableViewDataSource, RxTableViewDataSourceType {
    
    //Gets called on tableView.rx_elements.bindTo methods
    func tableView(_ tableView: UITableView, observedEvent: Event<[(day: String, forecasts: [ForecastModel])]>) {
        
        switch observedEvent {
        case .next(let items):
            tableViewData = items
        case .error(let error):
            print(error)
            presentError()
        case .completed:
            tableViewData = nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableViewData?[section].day
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewData?[section].forecasts.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "forecastCell", for: indexPath) as! ForecastTableViewCell
        
        guard let forecast = tableViewData?[indexPath.section].forecasts[indexPath.row] else {
            return cell
        }
        
        cell.cityDegreesLabel.text = forecast.temp
        cell.dateLabel.text = forecast.time
        cell.weatherMessageLabel.text = forecast.description
        return cell
    }
}

extension WeatherOverviewViewController: UITableViewDelegate {}
