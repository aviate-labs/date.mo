import { time = _now; nat64ToNat } = "mo:⛔";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import FmtNat "mo:fmt/Nat";
import Result "mo:base/Result";
import Float "mo:base/Float";
import Int "mo:base/Int";

module {
    private let NANO_SEC  : Time =                      1;
    private let SECOND    : Time =          1_000_000_000; // 1e9.
    private let MINUTE    : Time =         60_000_000_000;
    private let HOUR      : Time =      3_600_000_000_000;
    private let DAY       : Time =     86_400_000_000_000;
    private let YEAR      : Time = 31_536_000_000_000_000; // 365.
    private let LEAP_YEAR : Time = 31_622_400_000_000_000; // 366.

    /// System time is represent as nanoseconds since 1970-01-01.
    public type Time = Nat;

    public module Time = {
        public func now() : Time = nat64ToNat(_now());
    };

    public type Year = Nat;

    public module Year = {
        private let Y1970 : Year      = 1970;
        private let D1970             = 719_527; // Y1970 * DAYS_IN_YEAR + passedLeapYears(Y1970)
        private let DAYS_IN_YEAR      = 365;
        private let DAYS_IN_LEAP_YEAR = 366;

        public func fromTime(time : Time) : Year {
            var year  = Y1970 + time / YEAR;
            var days  = toDays(year);        // Overestimation.
            let days_ = D1970 + time / DAY;  // Correct amount of days.
            label l while (days_ < days) {
                year -= 1;
                days  -= if (isLeapYear(year)) {
                    DAYS_IN_LEAP_YEAR
                } else {
                    DAYS_IN_YEAR
                };
            };
            year;
        };

        public func toDays(year : Year) : Nat {
            year * DAYS_IN_YEAR + passedLeapYears(year);
        };

        public func toTime(year : Year) : Time {
            let days = year * DAYS_IN_YEAR + passedLeapYears(year);
            days * DAY;
        };

        public func timeSince1970(year : Year) : Time {
            if (year == Y1970) return 0;
            toTime(year) - D1970 * DAY;
        };

        public func isLeapYear(year : Year) : Bool {
            // The year must be evenly divisible by 4.
            if (year % 4   != 0) return false;
            // If the year can also be evenly divided by 100, it is not a leap year.
            if (year % 100 != 0) return true;
            // The year is also evenly divisible by 400. Then it is a leap year.
            year % 400 == 0;
        };

        public func passedLeapYears(year : Year) : Nat {
            let years = year - 1 : Nat;
            years / 4 - years / 100 + years / 400;
        };
    };

    public type Month = Nat;

    public module Month = {
        public func amountOfDays(year : Year, month : Month) : Nat = switch (month) {
            case (1 or 3 or 5 or 7 or 8 or 10 or 12) 31;
            case (4 or 6 or 9 or 11) 30;
            case (2) if (Year.isLeapYear(year)) { 29 } else { 28 };
            case (_) { assert(false); 0 }; // Are there more than 12 months?
        };
    };

    public type Date = {
        year   : Year;
        month  : Month;
        day    : Nat;
        hour   : Nat;
        minute : Nat;
        second : Nat;
        nano   : Nat;
    };

    public module Date = {
        public func fromTime(time : Time) : Date {
            let year = Year.fromTime(time);
            var nano = time - Year.timeSince1970(year) : Nat;

            var month = 0;
            label l while (month < 12) {
                month += 1;
                let n = DAY * Month.amountOfDays(year, month);
                if (nano <= n) break l;
                nano -= n;
            };

            var day = 0;
            label l while (day < Month.amountOfDays(year, month)) {
                day += 1;
                if (nano <= DAY) break l;
                nano -= DAY;
            };

            let hour   = (nano / 60 / 60 / SECOND) % 24;
            nano -= hour * HOUR;
            let minute = (nano / 60 / SECOND) % 60;
            nano -= minute * MINUTE;
            let second = (nano / SECOND) % 60;
            nano -= second * SECOND;
            
            {
                year; month; day;
                hour; minute; second;
                nano
            };
        };

        public func toTime({
            year; month; day; hour; minute; second; nano
        } : Date) : Time {
            var t = Year.timeSince1970(year);
            var i = 1; while (i < month) {
                t += Month.amountOfDays(year, i) * DAY;
                i += 1;
            };
            t + (day - 1) * DAY + hour * HOUR + minute * MINUTE + second * SECOND + nano;
        };

        private func padText(s : Text, desiredLength : Nat) : Text {
            if (desiredLength <= s.size()) {return s};
            padText("0" # s, desiredLength);
        };

        public func isoFormat({
            year; month; day; hour; minute; second; nano
        } : Date) : Text {
            // Always outputs to millisecond precision
            // Example "2016-02-29T23:59:59.000Z"

            let ms = Float.toInt(
                Float.nearest(Float.fromInt(nano) / 1_000_000)
            );

            (
                padText(Nat.toText(year),   2)  # "-" #
                padText(Nat.toText(month),  2)  # "-" #
                padText(Nat.toText(day),    2)  # "T" #
                padText(Nat.toText(hour),   2)  # ":" #
                padText(Nat.toText(minute), 2)  # ":" #
                padText(Nat.toText(second), 2)  # "." #
                padText(Int.toText(ms),     3)  # "Z"
            )
        };

        public func fromIsoFormat(date : Text) : Result.Result<Date, Text> {
            // Example: "2016-02-29T23:59:59Z"
            //   OR     "2016-02-29T23:59:59.456Z"

            let tokens = Text.tokens(date, #predicate(func (c : Char) : Bool {
                if (c == ':' or c == '-' or c == 'T' or c == 'Z' or c == '.') {true}
                else {false}
            }));

            let xs = switch (
                Array.mapResult<Text, Nat, Text>(
                    Iter.toArray(tokens),
                    func s {FmtNat.Parse(s, 10)}
                )
            ) {
                case (#ok(xs)) {xs};
                case (#err(_)) {return #err("ISO-8601 string improperly formatted")}
            };

            let _nanos = switch (xs.size()) {
                case (7) {xs[6] * 1_000_000};
                case (_) {0}
            };

            #ok({
                year=xs[0]; month=xs[1]; day=xs[2];
                hour=xs[3]; minute=xs[4]; second=xs[5];
                nano=_nanos;
            });
        };

        public func now() : Date = fromTime(Time.now());
    };
};






