//  Created by Dominik Hauser on 02.10.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import XCTest
@testable import BeenOutside

final class DayEntriesCalculatorTests: XCTestCase {

  var dateFormatter: DateFormatter!

  override func setUpWithError() throws {
    dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
  }

  override func tearDownWithError() throws {
    dateFormatter = nil
  }

  func test_durationFor_regionUpdateOnSameDay() {
    let regionUpdate1 = RegionUpdate(date: dateFormatter.date(from: "12.10.2022 14:01")!, updateTypeRaw: "exit")
    let regionUpdate2 = RegionUpdate(date: dateFormatter.date(from: "12.10.2022 16:02")!, updateTypeRaw: "enter")

    let result = DayEntriesCalculator.durationFor(date: dateFormatter.date(from: "12.10.2022 12:34")!, from: [regionUpdate1, regionUpdate2])

    let secondsInTwoHoursAndOneMinute = 2.0 * 60 * 60 + 1 * 60
    XCTAssertEqual(result, secondsInTwoHoursAndOneMinute, accuracy: 0.1)
  }

  func test_durationFor_exitOnPreviousDay() {
    let regionUpdate1 = RegionUpdate(date: dateFormatter.date(from: "11.10.2022 14:01")!, updateTypeRaw: "exit")
    let regionUpdate2 = RegionUpdate(date: dateFormatter.date(from: "12.10.2022 08:02")!, updateTypeRaw: "enter")

    let result = DayEntriesCalculator.durationFor(date: dateFormatter.date(from: "12.10.2022 12:34")!, from: [regionUpdate1, regionUpdate2])

    let secondsInEightHoursAndTwoMinutes = 8.0 * 60 * 60 + 2 * 60
    XCTAssertEqual(result, secondsInEightHoursAndTwoMinutes, accuracy: 0.1)
  }

  func test_durationFor_enterOnNextDay() {
    let regionUpdate1 = RegionUpdate(date: dateFormatter.date(from: "12.10.2022 22:02")!, updateTypeRaw: "exit")
    let regionUpdate2 = RegionUpdate(date: dateFormatter.date(from: "13.10.2022 08:01")!, updateTypeRaw: "enter")

    let result = DayEntriesCalculator.durationFor(date: dateFormatter.date(from: "12.10.2022 12:34")!, from: [regionUpdate1, regionUpdate2])

    let secondsInTwoHoursMinusTwoMinutes = 2.0 * 60 * 60 - 2 * 60
    XCTAssertEqual(result, secondsInTwoHoursMinusTwoMinutes, accuracy: 0.1)
  }

  func test_durationFor_exitOnPreviousAndEnterOnNextDay() {
    let regionUpdate1 = RegionUpdate(date: dateFormatter.date(from: "11.10.2022 22:02")!, updateTypeRaw: "exit")
    let regionUpdate2 = RegionUpdate(date: dateFormatter.date(from: "13.10.2022 08:01")!, updateTypeRaw: "enter")

    let result = DayEntriesCalculator.durationFor(date: dateFormatter.date(from: "12.10.2022 12:34")!, from: [regionUpdate1, regionUpdate2])

    let secondsInTwentyFourHours = 24.0 * 60 * 60
    XCTAssertEqual(result, secondsInTwentyFourHours, accuracy: 0.1)
  }

  func test_durationFor_exitAndEnterOnPreviousDay() {
    let regionUpdate1 = RegionUpdate(date: dateFormatter.date(from: "11.10.2022 08:02")!, updateTypeRaw: "exit")
    let regionUpdate2 = RegionUpdate(date: dateFormatter.date(from: "11.10.2022 10:01")!, updateTypeRaw: "enter")

    let result = DayEntriesCalculator.durationFor(date: dateFormatter.date(from: "12.10.2022 12:34")!, from: [regionUpdate1, regionUpdate2])

    XCTAssertEqual(result, 0.0, accuracy: 0.1)
  }

  func test_durationFor_exitAndEnterOnNextDay() {
    let regionUpdate1 = RegionUpdate(date: dateFormatter.date(from: "13.10.2022 08:02")!, updateTypeRaw: "exit")
    let regionUpdate2 = RegionUpdate(date: dateFormatter.date(from: "13.10.2022 10:01")!, updateTypeRaw: "enter")

    let result = DayEntriesCalculator.durationFor(date: dateFormatter.date(from: "12.10.2022 12:34")!, from: [regionUpdate1, regionUpdate2])

    XCTAssertEqual(result, 0.0, accuracy: 0.1)
  }

  func test_durationFor_yesterdayWhenEnterToday_shouldBeZero() {
    let regionUpdate1 = RegionUpdate(date: dateFormatter.date(from: "13.10.2022 10:01")!, updateTypeRaw: "enter")
    let regionUpdate2 = RegionUpdate(date: dateFormatter.date(from: "14.10.2022 10:01")!, updateTypeRaw: "exit")
    let regionUpdate3 = RegionUpdate(date: dateFormatter.date(from: "14.10.2022 16:01")!, updateTypeRaw: "enter")

    let result = DayEntriesCalculator.durationFor(date: dateFormatter.date(from: "12.10.2022 12:34")!, from: [regionUpdate1, regionUpdate2, regionUpdate3])

    XCTAssertEqual(result, 0.0, accuracy: 0.1)
  }
}
