function total_100ns_ints = cfDateToNTFS(curr_time)
    %curr_time = date vector with the format [year month day hour minute seconds]
    %total_100ns_int = number of 100 nanosecond intervals that have passed
    %                  since the time specified by the date vector
    %
    %This program is used to convert the current date and time to the number of
    %100 nanosecond intervals that have passed since January 1, 1601, which is
    %the time format that Windows NT uses.
    %
    %Josiah Renfree
    %April 2, 2007
    curr_year = curr_time(1);
    curr_month = curr_time(2);
    curr_day = curr_time(3);
    curr_hour = curr_time(4);
    curr_minute = curr_time(5);
    curr_second = curr_time(6);
    %***************** 100 ns intervals in previous years ********************
    %--- find number of years that have passed
    diff_years = curr_year - 1601;
    %--- Determine how many of those years are leap years
    years=1601:curr_year-1;
    mask400 = find(mod(years,400) == 0);
    mask100 = find(mod(years,100) == 0);
    mask4 = find(mod(years,4) == 0);
    num_leap_years = length(mask4) - length(mask100) + length(mask400);
    %--- Calculate number of days excluding the current year
    numdays_nly = (length(years) - num_leap_years).*365;
    numdays_ly = num_leap_years.*366;
    previous_days = numdays_nly + numdays_ly;
    %--- Convert previous years to number of 100 nanosecond intervals
    previous_hours = previous_days*24;
    previous_minutes = previous_hours*60;
    previous_seconds = previous_minutes*60;
    previous_ns = previous_seconds*10^9;
    previous_num_100ns_int = previous_ns/100;
    %*************************************************************************
    %************* 100 ns intervals in previous days of current year *********
    %--- find number of months that have passed in current year
    diff_months = curr_month - 1;
    date_vec = [31 28 31 30 31 30 31 31 30 31 30 31];
    %if current year is leap year
    if mod(curr_year,400) == 0
        leap = 1;
    elseif mod(curr_year,100) == 0
        leap = 0;
    elseif mod(curr_year,4) == 0
        leap = 1;
    else
        leap = 0;
    end
    %--- Calculate number of full days elapsed in current year ----
    months2days = sum(date_vec(1:diff_months));
    %if month conversion included leap year day
    if leap == 1 && curr_month > 2
        months2days = months2days + 1;
    end
    days_elapsed = curr_day - 1;
    full_days_elapsed = months2days + days_elapsed;
    %--------------------------------------------------------------
    %--- Convert to number of 100 nanosecond intervals
    full_100ns_int = (full_days_elapsed*24*60*60*10^9)/100;
    %*************************************************************************
    %************* 100 ns intervals in current day ***************************
    %--- Calculate number of 100 ns intervals in current day
    hours2ns = curr_hour * 60 * 60 * 10^9;
    minutes2ns = curr_minute * 60 * 10^9;
    seconds2ns = curr_second * 10^9;
    curr_day_100ns_int = (hours2ns + minutes2ns + seconds2ns)/100;
    %*************************************************************************
    %--- Combine all the calculations
    total_100ns_ints = curr_day_100ns_int + full_100ns_int + previous_num_100ns_int;
end
