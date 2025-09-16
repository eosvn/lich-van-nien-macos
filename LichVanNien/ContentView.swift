import SwiftUI

struct ContentView: View {
    // MARK: - Locale & Calendar
    private let viLocale = Locale(identifier: "vi_VN")
    private let vnTimeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current

    // MARK: - State
    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Int
    @State private var displayedYear: Int
    @State private var selectedTabIndex: Int = 0 // 0: Lịch, 1: Đổi ngày
    @State private var currentQuote: String = ""
    @State private var quoteOpacity: Double = 1.0
    let quoteTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    private let detailCardHeight: CGFloat = 240
    private let detailCardSpacing: CGFloat = 24
    private var detailCardsHeightMin: CGFloat { detailCardHeight }
    @State private var detailCardsHeight: CGFloat = 240

    // Sample event markers (day numbers in the displayed month)
    @State private var importantEventDays: Set<Int> = [1, 15]
    @State private var normalEventDays: Set<Int> = [7, 26]
    

    // MARK: - Init
    init() {
        let today = Date()
        let cal = Calendar.current
        _displayedMonth = State(initialValue: cal.component(.month, from: today))
        _displayedYear = State(initialValue: cal.component(.year, from: today))
    }
    

    // MARK: - Body
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 16) {
                topNavigationBar
                Group {
                    if selectedTabIndex == 0 {
                        LazyVStack(spacing: 16) {
                            monthYearPickerBar
                            calendarGrid
                            detailSection
                        }
                    } else {
                        DateConversionView(
                            selectedDate: $selectedDate,
                            displayedMonth: $displayedMonth,
                            displayedYear: $displayedYear
                        )
                    }
                }
                .transaction { txn in
                    txn.disablesAnimations = false
                }
            }
            .padding(20)
            .animation(.easeInOut(duration: 0.2), value: selectedTabIndex)
        }
        .environment(\.locale, viLocale)
        .onAppear { updateQuote(initial: true) }
        .onReceive(quoteTimer) { _ in updateQuote() }
    }

    // MARK: - Top Navigation
    private var topNavigationBar: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(spacing: 2) {
                    Picker("", selection: $selectedTabIndex) {
                        Text("Lịch").tag(0)
                        Text("Đổi ngày").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: jumpToToday) {
                        Text("Hôm nay")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(PrimaryTextButtonStyle())

                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(IconButtonStyle())

                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(IconButtonStyle())
                }
            }
        }
    }

    // MARK: - Month/Year Dropdowns
    private var monthYearPickerBar: some View {
        HStack(spacing: 12) {
            Picker("Tháng", selection: $displayedMonth) {
                ForEach(1...12, id: \.self) { month in
                    Text(String(month)).tag(month)
                }
            }
            .frame(width: 100)
            .background(AppColors.surface)
            .cornerRadius(8)
            .onChange(of: displayedMonth) { _, _ in syncSelectedDateWithinMonth() }

            Picker("Năm", selection: $displayedYear) {
                ForEach(1900...2100, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .frame(width: 120)
            .background(AppColors.surface)
            .cornerRadius(8)
            .onChange(of: displayedYear) { _, _ in syncSelectedDateWithinMonth() }

            Spacer()

            Text("\(String(displayedMonth))/\(String(displayedYear))")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 6) {
            // Weekday headers (Mon -> Sun)
            let columns = Array(repeating: GridItem(.flexible(minimum: 28, maximum: .infinity), spacing: 4), count: 7)

            HStack {
                ForEach(0..<7, id: \.self) { index in
                    let name = weekdayName(forMondayBasedIndex: index + 1)
                    Text(name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(index >= 5 ? AppColors.weekend : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(datesForDisplayedMonth(), id: \.self) { date in
                    DayCell(
                        date: date,
                        isInCurrentMonth: isInDisplayedMonth(date),
                        isToday: isSameDay(date, Date()),
                        isSelected: isSameDay(date, selectedDate),
                        isWeekend: isWeekend(date),
                        solarDay: dayComponent(date),
                        lunarDay: lunarDayComponent(date),
                        lunarMonth: lunarMonthComponent(date),
                        hasImportantEvent: hasImportantEvent(date),
                        hasNormalEvent: hasNormalEvent(date)
                    )
                    .onTapGesture {
                        selectedDate = date
                        displayedMonth = Calendar.current.component(.month, from: date)
                        displayedYear = Calendar.current.component(.year, from: date)
                    }
                }
            }
        }
    }

    // MARK: - Detail Section
    private var detailSection: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 24) {

                // ===== Left: Dương lịch =====
                VStack(alignment: .center, spacing: 6) {
                    Text("Dương lịch")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)

                    Text(CalendarUtils.gregorianMonthYear(selectedDate))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)

                    Text("\(dayComponent(selectedDate))")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, 2)

                    Text(CalendarUtils.weekdayString(selectedDate))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    Text(currentQuote)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top, 4)
                        .opacity(quoteOpacity)
                        .animation(.easeInOut(duration: 0.25), value: quoteOpacity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // GIỮ nội dung bám đỉnh khi card cao lên
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.divider, lineWidth: 1)
                )
                // GÁN HEIGHT = MAX(newHeight, min)
                .frame(height: max(detailCardsHeight, detailCardsHeightMin))
                // ĐO CHIỀU CAO THỰC (trước khi ép) để lấy MAX cho cả 2 bên
                .background(HeightReader())

                // ===== Right: Âm lịch =====
                VStack(alignment: .center, spacing: 6) {
                    Text("Âm lịch")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)

                    let lunar = CalendarUtils.lunarComponents(selectedDate)

                    Text("Tháng \(String(lunar.month))\(lunar.isLeap ? " (nhuận)" : ""), năm  \(CalendarUtils.canChiForYear(selectedDate))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)

                    Text("\(lunar.day)")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, 2)

                    HStack(spacing: 12) {
                        Text("Ngày \(CalendarUtils.canChiForDay(selectedDate))")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("Tháng \(CalendarUtils.canChiForMonth(selectedDate))")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }

                    Text("Giờ Hoàng Đạo:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)

                    let hours = CalendarUtils.hoangDaoHours(for: selectedDate)
                    WrapGrid(items: hours, spacing: 4) { hour in
                        Text(hour)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // GIỮ nội dung bám đỉnh khi card cao lên
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.divider, lineWidth: 1)
                )
                // GÁN HEIGHT = MAX(newHeight, min)
                .frame(height: max(detailCardsHeight, detailCardsHeightMin))
                // ĐO CHIỀU CAO THỰC (trước khi ép) để lấy MAX cho cả 2 bên
                .background(HeightReader())

            }
            .frame(maxWidth: 760)
            .onPreferenceChange(CardHeightKey.self) { newHeight in
                // LẤY MAX HEIGHT từ 2 card (do PreferenceKey reduce = max)
                // rồi lưu vào @State để 2 card .frame(height:) dùng chung
                detailCardsHeight = max(newHeight, detailCardsHeightMin)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }


    // MARK: - Actions
    private func previousMonth() {
        var month = displayedMonth - 1
        var year = displayedYear
        if month < 1 {
            month = 12
            year -= 1
        }
        displayedMonth = month
        displayedYear = year
        syncSelectedDateWithinMonth()
    }

    private func nextMonth() {
        var month = displayedMonth + 1
        var year = displayedYear
        if month > 12 {
            month = 1
            year += 1
        }
        displayedMonth = month
        displayedYear = year
        syncSelectedDateWithinMonth()
    }

    private func jumpToToday() {
        let today = Date()
        let cal = Calendar.current
        displayedMonth = cal.component(.month, from: today)
        displayedYear = cal.component(.year, from: today)
        selectedDate = today
    }

    private func syncSelectedDateWithinMonth() {
        // Keep the selected day if possible, clamp to last day of month otherwise
        let cal = Calendar.current
        let currentDay = cal.component(.day, from: selectedDate)
        let lastDay = daysInMonth(year: displayedYear, month: displayedMonth)
        let clampedDay = min(currentDay, lastDay)
        if let newDate = dateFromComponents(year: displayedYear, month: displayedMonth, day: clampedDay) {
            selectedDate = newDate
        }
    }

    // MARK: - Calendar Helpers
    private func datesForDisplayedMonth() -> [Date] {
        // Build a 6x7 grid (42 days) containing days of previous/next months as needed
        guard let firstOfMonth = dateFromComponents(year: displayedYear, month: displayedMonth, day: 1) else {
            return []
        }
        let cal = Calendar.current
        let weekdayUS = cal.component(.weekday, from: firstOfMonth) // 1=Sun..7=Sat
        let weekdayMonBased = ((weekdayUS + 5) % 7) + 1 // 1=Mon..7=Sun
        let leading = weekdayMonBased - 1 // number of preceding days

        let daysThisMonth = daysInMonth(year: displayedYear, month: displayedMonth)

        // previous month
        var prevMonth = displayedMonth - 1
        var prevYear = displayedYear
        if prevMonth < 1 { prevMonth = 12; prevYear -= 1 }
        let daysPrevMonth = daysInMonth(year: prevYear, month: prevMonth)

        var dates: [Date] = []
        // Leading days from previous month
        for i in stride(from: leading - 1, through: 0, by: -1) {
            if let d = dateFromComponents(year: prevYear, month: prevMonth, day: daysPrevMonth - i) {
                dates.append(d)
            }
        }
        // Current month days
        for day in 1...daysThisMonth {
            if let d = dateFromComponents(year: displayedYear, month: displayedMonth, day: day) {
                dates.append(d)
            }
        }
        // Trailing days from next month to reach 42
        var nextMonthVal = displayedMonth + 1
        var nextYearVal = displayedYear
        if nextMonthVal > 12 { nextMonthVal = 1; nextYearVal += 1 }
        var nextDay = 1
        while dates.count < 42 {
            if let d = dateFromComponents(year: nextYearVal, month: nextMonthVal, day: nextDay) {
                dates.append(d)
            }
            nextDay += 1
        }
        return dates
    }

    private func isInDisplayedMonth(_ date: Date) -> Bool {
        let cal = Calendar.current
        return cal.component(.month, from: date) == displayedMonth && cal.component(.year, from: date) == displayedYear
    }

    private func isWeekend(_ date: Date) -> Bool {
        let cal = Calendar.current
        let weekdayUS = cal.component(.weekday, from: date)
        let weekdayMonBased = ((weekdayUS + 5) % 7) + 1
        return weekdayMonBased >= 6 // Sat/Sun
    }

    private func dayComponent(_ date: Date) -> Int {
        Calendar.current.component(.day, from: date)
    }

    private func lunarDayComponent(_ date: Date) -> Int {
        lunarComponents(date).day
    }
    
    private func lunarMonthComponent(_ date: Date) -> Int {
        lunarComponents(date).month
    }

    private func lunarComponents(_ date: Date) -> (day: Int, month: Int, year: Int, isLeap: Bool) {
        var lunarCal = Calendar(identifier: .chinese)
        lunarCal.timeZone = vnTimeZone
        let comps = lunarCal.dateComponents([.day, .month, .year, .isLeapMonth], from: date)
        return (comps.day ?? 0, comps.month ?? 0, comps.year ?? 0, comps.isLeapMonth ?? false)
    }

    private func hasImportantEvent(_ date: Date) -> Bool {
        if !isInDisplayedMonth(date) { return false }
        return importantEventDays.contains(dayComponent(date))
    }

    private func hasNormalEvent(_ date: Date) -> Bool {
        if !isInDisplayedMonth(date) { return false }
        return normalEventDays.contains(dayComponent(date))
    }

    private func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        let cal = Calendar.current
        return cal.isDate(lhs, inSameDayAs: rhs)
    }

    private func daysInMonth(year: Int, month: Int) -> Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        let cal = Calendar.current
        guard let date = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: date) else { return 30 }
        return range.count
    }

    private func dateFromComponents(year: Int, month: Int, day: Int) -> Date? {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = 12 // midday to avoid DST issues
        return Calendar.current.date(from: comps)
    }

    private func weekdayName(forMondayBasedIndex index: Int) -> String {
        // 1=Mon..7=Sun
        let names = ["Th 2", "Th 3", "Th 4", "Th 5", "Th 6", "Th 7", "CN"]
        return names[max(1, min(7, index)) - 1]
    }

    // MARK: - Formatting & Texts
    private func weekdayString(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = viLocale
        df.timeZone = vnTimeZone
        df.dateFormat = "EEEE"
        return df.string(from: date).capitalized
    }

    private func gregorianMonthYear(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = viLocale
        df.timeZone = vnTimeZone
        df.dateFormat = "LLLL yyyy"
        return df.string(from: date).capitalized
    }

    private func quoteOfTheDay() -> String {
        // Simple rotating quotes collection
        // let quotes = [
        //     "Hôm nay làm việc của hôm nay.",
        //     "Thành công là một hành trình, không phải đích đến.",
        //     "Kiên trì là chìa khóa của mọi cánh cửa.",
        //     "Sống là cho đâu chỉ nhận riêng mình."
        // ]
        let idx = Calendar.current.component(.day, from: Date()) % quotes.count
        return quotes[idx]
    }

    // MARK: - Can Chi & Hoàng Đạo (simplified)
    private func canChiForDay(_ date: Date) -> String {
        // This is a simplified approximation for demo purposes
        let can = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
        let chi = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]
        let base = DateComponents(calendar: Calendar(identifier: .gregorian), year: 1984, month: 2, day: 2).date! // Giáp Tý approx
        let days = Int((date.timeIntervalSinceReferenceDate - base.timeIntervalSinceReferenceDate) / 86400.0)
        let canStr = can[((days % 10) + 10) % 10]
        let chiStr = chi[((days % 12) + 12) % 12]
        return "\(canStr) \(chiStr)"
    }

    private func canChiForMonth(_ date: Date) -> String {
        // Simplified: use lunar month chi and approximate can
        let can = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
        let chi = ["Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi", "Tý", "Sửu"] // months start from Dần
        let lunar = lunarComponents(date)
        let chiStr = chi[(lunar.month - 1 + 12) % 12]
        // crude can based on lunar year and month
        let canIndex = ((lunar.year % 10) + (lunar.month - 1)) % 10
        let canStr = can[(canIndex + 10) % 10]
        return "\(canStr) \(chiStr)"
    }
    
    func canChiForYear(_ date: Date) -> String {
        let can = ["Giáp", "Ất", "Bính", "Đinh", "Mậu",
                   "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
        let chi = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ",
                   "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]

        // Dùng lịch dương để lấy năm
        let year = Calendar(identifier: .gregorian).component(.year, from: date)

        // Offset chuẩn: 1984 là Giáp Tý
        let canIndex = (year + 6) % 10
        let chiIndex = (year + 8) % 12

        return "\(can[canIndex]) \(chi[chiIndex])"
    }



    private func hoangDaoHours(for date: Date) -> [String] {
        // Simplified mapping by day chi index
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
        // Determine day chi index
        _ = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]
        let base = DateComponents(calendar: Calendar(identifier: .gregorian), year: 1984, month: 2, day: 2).date!
        let days = Int((date.timeIntervalSinceReferenceDate - base.timeIntervalSinceReferenceDate) / 86400.0)
        let chiIndex = ((days % 12) + 12) % 12
        let goodBranches = chiSlots[chiIndex]
        // Map branches to compact hour strings
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

    private func updateQuote(initial: Bool = false) {
        if quotes.isEmpty { return }
        // Pause updates if not in main calendar tab
        if !initial && selectedTabIndex != 0 { return }
        if initial {
            currentQuote = quotes.randomElement() ?? ""
            quoteOpacity = 1.0
            return
        }
        // Fade out, change, then fade in
        withAnimation(.easeInOut(duration: 0.2)) { quoteOpacity = 0.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            var next = quotes.randomElement() ?? currentQuote
            if quotes.count > 1 {
                var attempts = 0
                while next == currentQuote && attempts < 5 {
                    next = quotes.randomElement() ?? currentQuote
                    attempts += 1
                }
            }
            currentQuote = next
            withAnimation(.easeInOut(duration: 0.25)) { quoteOpacity = 1.0 }
        }
    }
}

// PreferenceKey to compute max card height
//private struct CardHeightKey: PreferenceKey {
//    static var defaultValue: CGFloat = 0
//    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
//        value = max(value, nextValue())
//    }
//}

// A background reader to report its container height via preference
//private struct HeightReader: View {
//    var body: some View {
//        GeometryReader { proxy in
//            Color.clear
//                .preference(key: CardHeightKey.self, value: proxy.size.height)
//        }
//    }
//}

private var detailCardsHeight: CGFloat = 0           // CHO PHÉP GÁN (không còn lỗi 'let constant')
private let detailCardsHeightMin: CGFloat = 180             // chiều cao tối thiểu mong muốn

// MARK: - Day Cell
private struct DayCell: View {
    let date: Date
    let isInCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let isWeekend: Bool
    let solarDay: Int
    let lunarDay: Int
    let lunarMonth: Int
    let hasImportantEvent: Bool
    let hasNormalEvent: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(borderColor, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 4) {
                    Text("\(solarDay)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(solarTextColor)
                    Spacer()
                }

                Spacer()

                HStack {
                    Spacer()
                    Text(lunarDay == 1
                        ? "\(lunarDay)/\(lunarMonth)"
                        : "\(lunarDay)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(lunarTextColor)
                }
            }
            .padding(10)

            if hasImportantEvent || hasNormalEvent {
                Image(systemName: hasImportantEvent ? "star.fill" : "star")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(hasImportantEvent ? AppColors.eventImportant : AppColors.eventNormal)
                    .padding(6)
            }
        }
        .frame(minHeight: 40)
    }

    private var backgroundColor: Color {
        if isSelected || isToday { return AppColors.selectedBackground }
        return AppColors.surface
    }

    private var borderColor: Color {
        if isSelected || isToday { return AppColors.selectedBackground.opacity(0.9) }
        return AppColors.divider
    }

    private var solarTextColor: Color {
        if isSelected || isToday { return .white }
        if isWeekend && isInCurrentMonth { return AppColors.weekend }
        return isInCurrentMonth ? AppColors.textPrimary : AppColors.textTertiary
    }

    private var lunarTextColor: Color {
        if isSelected || isToday { return .white.opacity(0.9) }
        return isInCurrentMonth ? AppColors.textSecondary : AppColors.textTertiary
    }
}

// MARK: - Utilities
private struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)
            .frame(width: 28, height: 28)
            .background(AppColors.surface)
            .cornerRadius(6)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

private struct PrimaryTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(AppColors.selectedBackground)
            .cornerRadius(6)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

// WrapGrid now provided by CommonUI.swift

#Preview {
    ContentView()
        .frame(width: 980, height: 720)
}

