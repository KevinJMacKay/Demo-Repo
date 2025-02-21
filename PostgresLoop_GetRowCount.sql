DO $$
DECLARE
    current_row_count INTEGER;
    start_time TIMESTAMP := CURRENT_TIMESTAMP;
BEGIN
    LOOP
        -- Get the current row count
        EXECUTE 'SELECT COUNT(*) FROM dbo.org_users' INTO current_row_count;
       
        -- Insert the row count into the log table
        INSERT INTO row_count_log (table_name, row_count)
        VALUES ('dbo.org_users', current_row_count);
        
        -- Wait for 15 minutes
        PERFORM pg_sleep(900); -- 900 seconds = 15 minutes
        
        -- Check if 24 hours have passed
        IF CURRENT_TIMESTAMP - start_time >= INTERVAL '5 minutes' THEN
            EXIT;
        END IF;
    END LOOP;

END $$;