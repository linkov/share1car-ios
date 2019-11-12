//
//  StarCell.swift
//  share1car
//
//  Created by Alex Linkov on 11/12/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Cosmos
import Eureka
open class CustomRateCell: Cell<Int>, CellType {
    private var awakeFromNibCalled = false
    @IBOutlet weak var cosmosRating: CosmosView!
    @IBOutlet open weak var titleLabel: UILabel!
    
    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
//    deinit {
//        guard !awakeFromNibCalled else { return }
//        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIContentSizeCategory.didChangeNotification, object: nil)
//    }
//
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        awakeFromNibCalled = true
    }
    
//    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        fatalError("init(style:reuseIdentifier:) has not been implemented")
//    }
    
    open override func setup() {
        super.setup()
        
        cosmosRating.didTouchCosmos = valueChanged
        cosmosRating.didFinishTouchingCosmos = valueChanged
        
        selectionStyle = .none
        //custom settings for cosmos
        cosmosRating.settings.starSize = 50.0
        cosmosRating.settings.emptyBorderWidth = 1
        cosmosRating.settings.filledBorderWidth = 5
    }
    
    func valueChanged(_ rating: Double) {
        row.value = Int(rating)
        row.updateCell()
    }
    
    open override func update() {
        titleLabel.text = row.title
        row.value = Int(cosmosRating.rating)
    }
    
    private var customRateRow: CustomRateRow {
        return row as! CustomRateRow
    }
}
public final class CustomRateRow: Row<CustomRateCell>, RowType {
    
    required public init(tag: String?) {
        super.init(tag: tag)
        cellProvider = CellProvider<CustomRateCell>(nibName: "CustomRateCell", bundle: Bundle.main)
    }
}
