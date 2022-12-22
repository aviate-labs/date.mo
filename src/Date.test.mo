import Prim "mo:⛔";
import Nat "mo:base/Nat";
import D "mo:base/Debug";

import Date "Date";
import { describe; it; Suite } = "mo:testing/Suite";


let suite = Suite();

suite.run([
    describe("Date", [
        it("0", func () : Bool {
            Date.Date.fromTime(0) == {
                year = 1970; month = 1; day = 1; 
                hour = 0; minute = 0; second = 0;
                nano = 0;
            };
        }),
        it("1999/12/31 22:59:59", func () : Bool {
            let time = 946681199_000000000;
            let date_utc = Date.Date.fromTime(time);
            date_utc == {
                year = 1999; month = 12; day = 31; 
                hour = 22; minute = 59; second = 59;
                nano = 0;
            };
        }),
        it("2222/02/22 21:22:22", func () : Bool {
            let time = 7956912142_222222222;
            let date_utc = Date.Date.fromTime(time);
            if (date_utc != {
                year = 2222; month = 2; day = 22; 
                hour = 21; minute = 22; second = 22;
                nano = 222222222;
            }) return false;
            Date.Date.toTime(date_utc) == time;
        }),
        it("2016/02/29 23:59:59", func () : Bool {
            let time = 1456790399_000000000;
            let date_utc = Date.Date.fromTime(time);
            date_utc == {
                year = 2016; month = 2; day = 29;
                hour = 23; minute = 59; second = 59;
                nano = 0;
            }
        }),
        it("Outputs Correct ISO format", func() : Bool {
            let date_utc = {
                year = 2016; month = 2; day = 29;
                hour = 23; minute = 59; second = 59;
                nano = 0;
            };
            Date.Date.isoFormat(date_utc) == "2016-02-29T23:59:59Z";
        }),
        it("Converts an ISO text string into a Date object", func() : Bool {
            let date_iso = "2016-02-29T23:59:59Z";
            let date_utc = Date.Date.fromIsoFormat(date_iso);
            date_utc == #ok({
                year = 2016; month = 2; day = 29;
                hour = 23; minute = 59; second = 59;
                nano = 0;
            })
        }),
        it("Returns an #err when given a non-iso date", func() : Bool {
            let bad_date_iso = "201a6-02-29T23.3:59::59N";
            #err("ISO-8601 string improperly formatted") == Date.Date.fromIsoFormat(bad_date_iso)
        })
    ])
]);