# Date

Unix time in nanoseconds to/from a Motoko Date object.

Supports conversion to and from ISO 8601 UTC timestamps as well (Text).


## Usage

```motoko
import Date "mo:Date";

// Conversion to and from unix time

let time_ns = 7956912142_222222222;
let date_obj = Date.Date.fromTime(time_ns);

assert( Date.Date.toTime(date_obj) == time_ns );

assert( date_obj == {
                year = 2222; month = 2; day = 22; 
                hour = 21; minute = 22; second = 22;
                nano = 222222222;
            });



// Conversion to and from ISO 8601 UTC Timestamps (Text)

assert( Date.Date.toIsoFormat(date_obj) == "2222-02-22T21:22:22.222Z" );

assert( Date.Date.fromIsoFormat("2222-02-22T21:22:22.000Z") == #ok{
                year = 2222; month = 2; day = 22; 
                hour = 21; minute = 22; second = 22;
                nano = 0;
            } );


```
