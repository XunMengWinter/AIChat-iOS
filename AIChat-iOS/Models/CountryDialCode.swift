//
//  CountryDialCode.swift
//  AIChat-iOS
//

import Foundation

struct CountryDialCode: Identifiable, Hashable {
    let chineseName: String
    let englishName: String
    let isoCode: String
    let dialCode: String
    let apiValue: String
    let maxPhoneDigits: Int

    var id: String { isoCode }

    static let china = CountryDialCode(
        chineseName: "中国",
        englishName: "China",
        isoCode: "CN",
        dialCode: "+86",
        apiValue: "86",
        maxPhoneDigits: 11
    )

    static let popular: [CountryDialCode] = [
        china,
        CountryDialCode(chineseName: "美国", englishName: "United States", isoCode: "US", dialCode: "+1", apiValue: "1", maxPhoneDigits: 10),
        CountryDialCode(chineseName: "加拿大", englishName: "Canada", isoCode: "CA", dialCode: "+1", apiValue: "1", maxPhoneDigits: 10),
        CountryDialCode(chineseName: "日本", englishName: "Japan", isoCode: "JP", dialCode: "+81", apiValue: "81", maxPhoneDigits: 11),
        CountryDialCode(chineseName: "新加坡", englishName: "Singapore", isoCode: "SG", dialCode: "+65", apiValue: "65", maxPhoneDigits: 8),
        CountryDialCode(chineseName: "澳大利亚", englishName: "Australia", isoCode: "AU", dialCode: "+61", apiValue: "61", maxPhoneDigits: 9),
        CountryDialCode(chineseName: "新西兰", englishName: "New Zealand", isoCode: "NZ", dialCode: "+64", apiValue: "64", maxPhoneDigits: 10),
        CountryDialCode(chineseName: "英国", englishName: "United Kingdom", isoCode: "GB", dialCode: "+44", apiValue: "44", maxPhoneDigits: 10),
        CountryDialCode(chineseName: "法国", englishName: "France", isoCode: "FR", dialCode: "+33", apiValue: "33", maxPhoneDigits: 9),
        CountryDialCode(chineseName: "西班牙", englishName: "Spain", isoCode: "ES", dialCode: "+34", apiValue: "34", maxPhoneDigits: 9),
        CountryDialCode(chineseName: "意大利", englishName: "Italy", isoCode: "IT", dialCode: "+39", apiValue: "39", maxPhoneDigits: 10),
        CountryDialCode(chineseName: "韩国", englishName: "South Korea", isoCode: "KR", dialCode: "+82", apiValue: "82", maxPhoneDigits: 11),
        CountryDialCode(chineseName: "德国", englishName: "Germany", isoCode: "DE", dialCode: "+49", apiValue: "49", maxPhoneDigits: 11),
        CountryDialCode(chineseName: "印度", englishName: "India", isoCode: "IN", dialCode: "+91", apiValue: "91", maxPhoneDigits: 10),
        CountryDialCode(chineseName: "泰国", englishName: "Thailand", isoCode: "TH", dialCode: "+66", apiValue: "66", maxPhoneDigits: 9),
        CountryDialCode(chineseName: "马来西亚", englishName: "Malaysia", isoCode: "MY", dialCode: "+60", apiValue: "60", maxPhoneDigits: 10)
    ]

    static func displayDialCode(for countryCode: String?) -> String {
        guard let countryCode else { return china.dialCode }
        let digits = countryCode.filter(\.isNumber)
        guard !digits.isEmpty else { return china.dialCode }
        return "+\(digits)"
    }
}
