import SwiftUI

struct DateConversionView: View, Equatable {
    static func == (lhs: DateConversionView, rhs: DateConversionView) -> Bool {
        // Re-render only when bindings point to different instances (not typical) — always false to avoid identity-based diffing
        false
    }

    @Binding var selectedDate: Date
    @Binding var displayedMonth: Int
    @Binding var displayedYear: Int

    // Solar inputs
    @State private var solarDay: Int = 1
    @State private var solarMonth: Int = 1
    @State private var solarYear: Int = 2000

    // Lunar inputs
    @State private var lunarDay: Int = 1
    @State private var lunarMonth: Int = 1
    @State private var lunarYearDisplay: Int = 2000
    @State private var lunarIsLeap: Bool = false

    @State private var internalUpdate: Bool = false
    private let conversionCardHeight: CGFloat = 240
    private let cardCornerRadius: CGFloat = 12

    private enum InputSide { case solar, lunar }
    @State private var activeInput: InputSide = .solar

    var body: some View {
        // DÙNG ScrollView để tránh tràn khi ở trong Form
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Đổi ngày")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("Chọn ngày/tháng/năm để chuyển đổi giữa Dương lịch và Âm lịch.")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)

                // TỰ ĐỘNG CHUYỂN 2 CỘT -> 1 CỘT KHI HẸP
                ViewThatFits(in: .horizontal) {
                    // --- 2 cột khi đủ rộng ---
                    HStack(alignment: .top, spacing: 24) {
                        solarCard
                        lunarCard
                    }

                    // --- 1 cột khi hẹp ---
                    VStack(alignment: .leading, spacing: 16) {
                        solarCard
                        lunarCard
                    }
                }
                // KHÔNG giới hạn cứng maxWidth trong Form
                // .frame(maxWidth: 760) // nếu cần dùng ngoài Form thì bật dòng này
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        // KHÔNG dùng maxHeight: .infinity ở container khi ở trong Form
        .onAppear(perform: initializeFromSelectedDate)
    }

    // MARK: - Subviews
    private var solarCard: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: 10) {
                Picker("Ngày", selection: $solarDay) {
                    ForEach(1..<(CalendarUtils.daysInSolarMonth(year: solarYear, month: solarMonth) + 1), id: \.self) { d in
                        Text(String(d)).tag(d)
                    }
                }
                .frame(width: 90)
                .background(AppColors.surface)
                .cornerRadius(8)
                .onChange(of: solarDay) { _, _ in solarChanged() }

                Picker("Tháng", selection: $solarMonth) {
                    ForEach(1...12, id: \.self) { m in
                        Text(String(m)).tag(m)
                    }
                }
                .frame(width: 100)
                .background(AppColors.surface)
                .cornerRadius(8)
                .onChange(of: solarMonth) { _, _ in
                    let lastDay = CalendarUtils.daysInSolarMonth(year: solarYear, month: solarMonth)
                    if solarDay > lastDay { solarDay = lastDay }
                    solarChanged()
                }

                Picker("Năm", selection: $solarYear) {
                    ForEach(1900...2100, id: \.self) { y in
                        Text(String(y)).tag(y)
                    }
                }
                .frame(width: 120)
                .background(AppColors.surface)
                .cornerRadius(8)
                .onChange(of: solarYear) { _, _ in
                    let lastDay = CalendarUtils.daysInSolarMonth(year: solarYear, month: solarMonth)
                    if solarDay > lastDay { solarDay = lastDay }
                    solarChanged()
                }
            }
            .padding(.top, 6)

            Text("Dương lịch")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            Text(CalendarUtils.gregorianMonthYear(selectedDate))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)

            Text("\(solarDay)")
                .font(.system(size: 54, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, 2)

            Text(CalendarUtils.weekdayString(selectedDate))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
        }
        // QUAN TRỌNG: không dùng maxHeight: .infinity trong Form
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(AppColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(AppColors.divider, lineWidth: 1)
        )
        .frame(height: conversionCardHeight)
    }

    private var lunarCard: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: 10) {
                Picker("Ngày", selection: $lunarDay) {
                    ForEach(1..<(CalendarUtils.daysInLunarMonth(gregorianYear: lunarYearDisplay, month: lunarMonth, isLeap: lunarIsLeap) + 1), id: \.self) { d in
                        Text(String(d)).tag(d)
                    }
                }
                .frame(width: 90)
                .background(AppColors.surface)
                .cornerRadius(8)
                .onChange(of: lunarDay) { _, _ in lunarChanged() }

                Picker("Tháng", selection: $lunarMonth) {
                    ForEach(1...12, id: \.self) { m in
                        Text(String(m)).tag(m)
                    }
                }
                .frame(width: 100)
                .background(AppColors.surface)
                .cornerRadius(8)
                .onChange(of: lunarMonth) { _, _ in
                    let lastDay = CalendarUtils.daysInLunarMonth(gregorianYear: lunarYearDisplay, month: lunarMonth, isLeap: lunarIsLeap)
                    if lunarDay > lastDay { lunarDay = lastDay }
                    lunarChanged()
                }

                Picker("Năm", selection: $lunarYearDisplay) {
                    ForEach(1900...2100, id: \.self) { y in
                        Text(String(y)).tag(y)
                    }
                }
                .frame(width: 120)
                .background(AppColors.surface)
                .cornerRadius(8)
                .onChange(of: lunarYearDisplay) { _, _ in
                    let lastDay = CalendarUtils.daysInLunarMonth(gregorianYear: lunarYearDisplay, month: lunarMonth, isLeap: lunarIsLeap)
                    if lunarDay > lastDay { lunarDay = lastDay }
                    lunarChanged()
                }

                Toggle(isOn: $lunarIsLeap) {
                    Text("Nhuận")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
                .toggleStyle(.switch)
            }
            .onChange(of: lunarIsLeap) { _, _ in
                let lastDay = CalendarUtils.daysInLunarMonth(gregorianYear: lunarYearDisplay, month: lunarMonth, isLeap: lunarIsLeap)
                if lunarDay > lastDay { lunarDay = lastDay }
                lunarChanged()
            }
            .padding(.top, 6)

            Text("Âm lịch")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            let lunar = CalendarUtils.lunarComponents(selectedDate)
            Text("Tháng \(lunar.month)\(lunar.isLeap ? " (nhuận)" : ""), năm \(CalendarUtils.canChiForYearFromGregorian(lunarYearDisplay))")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true) // cho phép xuống dòng trong Form

            Text("\(lunarDay)")
                .font(.system(size: 54, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, 2)

            HStack(spacing: 12) {
                Text("Ngày \(CalendarUtils.canChiForDay(selectedDate))")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                Spacer(minLength: 8)
                Text("Tháng \(CalendarUtils.canChiForMonth(selectedDate))")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }

            Text("Giờ Hoàng Đạo:")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            WrapGrid(items: CalendarUtils.hoangDaoHours(for: selectedDate), spacing: 4) { hour in
                Text(hour)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .top) // bỏ maxHeight: .infinity
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .fill(AppColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(AppColors.divider, lineWidth: 1)
        )
        .frame(height: conversionCardHeight)
    }

    // MARK: - Actions
    private func solarChanged() {
        if internalUpdate { return }
        activeInput = .solar
        let cal = Calendar(identifier: .gregorian)
        var comps = DateComponents()
        comps.year = solarYear
        comps.month = solarMonth
        comps.day = solarDay
        comps.hour = 12
        if let date = cal.date(from: comps) {
            internalUpdate = true
            updateLunarFields(from: date)
            selectedDate = date
            displayedMonth = solarMonth
            displayedYear = solarYear
            internalUpdate = false
        }
    }

    private func lunarChanged() {
        if internalUpdate { return }
        activeInput = .lunar
        if let date = dateFromLunarInputs() {
            internalUpdate = true
            updateSolarFields(from: date)
            selectedDate = date
            displayedMonth = Calendar.current.component(.month, from: date)
            displayedYear = Calendar.current.component(.year, from: date)
            internalUpdate = false
        }
    }

    private func initializeFromSelectedDate() {
        updateSolarFields(from: selectedDate)
        updateLunarFields(from: selectedDate)
    }

    private func updateSolarFields(from date: Date) {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.day, .month, .year], from: date)
        solarDay = comps.day ?? 1
        solarMonth = comps.month ?? 1
        solarYear = comps.year ?? 2000
    }

    private func updateLunarFields(from date: Date) {
        let ccal = Calendar(identifier: .chinese)
        let comps = ccal.dateComponents([.era, .year, .month, .day, .isLeapMonth], from: date)
        lunarDay = comps.day ?? 1
        lunarMonth = comps.month ?? 1
        lunarIsLeap = comps.isLeapMonth ?? false
        lunarYearDisplay = Calendar.current.component(.year, from: date)
    }

    // MARK: - Helpers
    private func dateFromLunarInputs() -> Date? {
        let ccal = Calendar(identifier: .chinese)
        guard let eraYear = CalendarUtils.chineseEraYear(forGregorianYear: lunarYearDisplay) else { return nil }
        let maxDay = CalendarUtils.daysInLunarMonth(gregorianYear: lunarYearDisplay, month: lunarMonth, isLeap: lunarIsLeap)
        let clampedDay = min(lunarDay, maxDay)
        var comps = DateComponents()
        comps.era = eraYear.era
        comps.year = eraYear.year
        comps.month = lunarMonth
        comps.isLeapMonth = lunarIsLeap
        comps.day = clampedDay
        comps.hour = 12
        return ccal.date(from: comps)
    }

    private func formattedLunarSummary() -> String {
        let leap = lunarIsLeap ? " (nhuận)" : ""
        return "\(lunarDay)/\(lunarMonth)\(leap), \(CalendarUtils.canChiForYearFromGregorian(lunarYearDisplay))"
    }

    private func formattedSolarSummary() -> String {
        return String(format: "%02d/%02d/%04d", solarDay, solarMonth, solarYear)
    }
}
