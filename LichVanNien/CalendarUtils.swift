import Foundation
import SwiftUI

struct CalendarUtils {
    // Locale & TimeZone
    static let viLocale = Locale(identifier: "vi_VN")
    static let vnTimeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current

    // Shared Can/Chi
    static let heavenlyStems: [String] = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
    static let earthlyBranches: [String] = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]
    // Lunar months traditionally start from Dần
    static let monthlyBranches: [String] = ["Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi", "Tý", "Sửu"]

    // MARK: - Public helpers
    static func weekdayString(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = viLocale
        df.timeZone = vnTimeZone
        df.dateFormat = "EEEE"
        return df.string(from: date).capitalized
    }

    static func gregorianMonthYear(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = viLocale
        df.timeZone = vnTimeZone
        df.dateFormat = "LLLL yyyy"
        return df.string(from: date).capitalized
    }

    static func lunarComponents(_ date: Date) -> (day: Int, month: Int, year: Int, isLeap: Bool) {
        var lunarCal = Calendar(identifier: .chinese)
        lunarCal.timeZone = vnTimeZone
        let comps = lunarCal.dateComponents([.day, .month, .year, .isLeapMonth], from: date)
        return (comps.day ?? 0, comps.month ?? 0, comps.year ?? 0, comps.isLeapMonth ?? false)
    }

    static func canChiForDay(_ date: Date) -> String {
        let base = DateComponents(calendar: Calendar(identifier: .gregorian), year: 1984, month: 2, day: 2).date!
        let days = Int((date.timeIntervalSinceReferenceDate - base.timeIntervalSinceReferenceDate) / 86400.0)
        let canStr = heavenlyStems[((days % 10) + 10) % 10]
        let chiStr = earthlyBranches[((days % 12) + 12) % 12]
        return "\(canStr) \(chiStr)"
    }

    static func canChiForMonth(_ date: Date) -> String {
        let lunar = lunarComponents(date)
        let chiStr = monthlyBranches[(lunar.month - 1 + 12) % 12]
        // crude can based on lunar year and month
        let canIndex = ((lunar.year % 10) + (lunar.month - 1)) % 10
        let canStr = heavenlyStems[(canIndex + 10) % 10]
        return "\(canStr) \(chiStr)"
    }

    static func canChiForYear(_ date: Date) -> String {
        let year = Calendar(identifier: .gregorian).component(.year, from: date)
        let canIndex = (year + 6) % 10
        let chiIndex = (year + 8) % 12
        return "\(heavenlyStems[canIndex]) \(earthlyBranches[chiIndex])"
    }

    static func canChiForYearFromGregorian(_ year: Int) -> String {
        let canIndex = (year + 6) % 10
        let chiIndex = (year + 8) % 12
        return "\(heavenlyStems[canIndex]) \(earthlyBranches[chiIndex])"
    }

    static func hoangDaoHours(for date: Date) -> [String] {
        let chiSlots = [
            ["Tý", "Sửu", "Mão", "Ngọ", "Thân", "Dậu"],
            ["Dần", "Mão", "Tỵ", "Thân", "Tuất", "Hợi"],
            ["Tý", "Dần", "Mão", "Ngọ", "Mùi", "Dậu"],
            ["Sửu", "Thìn", "Tỵ", "Thân", "Dậu", "Hợi"],
            ["Tý", "Mão", "Thìn", "Ngọ", "Thân", "Hợi"],
            ["Dần", "Thìn", "Tỵ", "Mùi", "Tuất", "Hợi"],
            ["Tý", "Sửu", "Thìn", "Ngọ", "Mùi", "Tuất"],
            ["Sửu", "Mão", "Ngọ", "Mùi", "Dậu", "Hợi"],
            ["Tý", "Dần", "Mão", "Tỵ", "Thân", "Tuất"],
            ["Sửu", "Thìn", "Ngọ", "Mùi", "Dậu", "Hợi"],
            ["Tý", "Mão", "Thìn", "Ngọ", "Thân", "Tuất"],
            ["Dần", "Tỵ", "Mùi", "Thân", "Tuất", "Hợi"]
        ]
        let base = DateComponents(calendar: Calendar(identifier: .gregorian), year: 1984, month: 2, day: 2).date!
        let days = Int((date.timeIntervalSinceReferenceDate - base.timeIntervalSinceReferenceDate) / 86400.0)
        let chiIndex = ((days % 12) + 12) % 12
        let goodBranches = chiSlots[chiIndex]
        let allHours: [(String, (Int, Int))] = [
            ("Tý", (23, 1)), ("Sửu", (1, 3)), ("Dần", (3, 5)), ("Mão", (5, 7)),
            ("Thìn", (7, 9)), ("Tỵ", (9, 11)), ("Ngọ", (11, 13)), ("Mùi", (13, 15)),
            ("Thân", (15, 17)), ("Dậu", (17, 19)), ("Tuất", (19, 21)), ("Hợi", (21, 23))
        ]
        return allHours
            .filter { goodBranches.contains($0.0) }
            .map { branch, range in
                let startStr = range.0 == 23 ? "23h" : "\(range.0)h"
                let endStr = range.1 == 1 ? "1h" : "\(range.1)h"
                return "\(branch) (\(startStr)-\(endStr))"
            }
    }

    static func daysInSolarMonth(year: Int, month: Int) -> Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        let cal = gregorianCalendar()
        guard let date = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: date) else { return 30 }
        return range.count
    }

    static func daysInLunarMonth(gregorianYear: Int, month: Int, isLeap: Bool) -> Int {
        let ccal = chineseCalendar()
        guard let eraYear = chineseEraYear(forGregorianYear: gregorianYear) else { return 30 }
        var comps = DateComponents()
        comps.era = eraYear.era
        comps.year = eraYear.year
        comps.month = month
        comps.isLeapMonth = isLeap
        comps.day = 1
        guard let d = ccal.date(from: comps),
              let range = ccal.range(of: .day, in: .month, for: d) else { return 30 }
        return range.count
    }

    // MARK: - Private
    private static func gregorianCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = viLocale
        cal.timeZone = vnTimeZone
        return cal
    }

    private static func chineseCalendar() -> Calendar {
        var cal = Calendar(identifier: .chinese)
        cal.locale = viLocale
        cal.timeZone = vnTimeZone
        return cal
    }

    static func chineseEraYear(forGregorianYear year: Int) -> (era: Int, year: Int)? {
        let ccal = chineseCalendar()
        var comps = DateComponents()
        comps.year = year
        comps.month = 6
        comps.day = 15
        comps.hour = 12
        guard let midOfYear = gregorianCalendar().date(from: comps) else { return nil }
        let cy = ccal.dateComponents([.era, .year], from: midOfYear)
        guard let era = cy.era, let y = cy.year else { return nil }
        return (era, y)
    }
}
