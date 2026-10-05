-- Question 1
DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS lab_sessions;

CREATE TABLE lab_sessions (
    session_id SERIAL PRIMARY KEY,
    session_name VARCHAR(80) NOT NULL,
    available_workstations INTEGER NOT NULL CHECK (available_workstations >= 0)
);

CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES lab_sessions(session_id),
    lecturer VARCHAR(80) NOT NULL,
    workstations INTEGER NOT NULL CHECK (workstations > 0),
    status VARCHAR(20) DEFAULT 'ACTIVE'
);

INSERT INTO lab_sessions (session_name, available_workstations) VALUES
('Monday 08:00 - Programming Lab', 20),
('Tuesday 10:00 - Database Lab', 5),
('Wednesday 14:00 - Networking Lab', 0),
('Friday 10:00 - ICT Lab', 5);


SELECT * FROM lab_sessions;


-- Question 2
DO $$
DECLARE
    v_available INTEGER;
    v_name VARCHAR(80);
BEGIN
    SELECT session_name, available_workstations INTO v_name, v_available
    FROM lab_sessions WHERE session_id = 3;
    
    IF v_available = 0 THEN
        RAISE NOTICE 'Session "%" is FULL.', v_name;
    ELSIF v_available <= 5 THEN
        RAISE NOTICE 'Session "%" is NEARLY FULL (% available).', v_name, v_available;
    ELSE
        RAISE NOTICE 'Session "%" has ENOUGH workstations (% available).', v_name, v_available;
    END IF;
END $$ LANGUAGE plpgsql;


-- Question 3
DO $$
DECLARE
    v_counter INTEGER := 1;
BEGIN
    RAISE NOTICE '--- Session Preparation Reminders ---';
    WHILE v_counter <= 3 LOOP
        RAISE NOTICE 'Preparation Reminder #%', v_counter;
        v_counter := v_counter + 1;
    END LOOP;
    
    RAISE NOTICE '--- Workstation Checks ---';
    FOR i IN 1..3 LOOP
        RAISE NOTICE 'Workstation Check #%', i;
    END LOOP;
END $$ LANGUAGE plpgsql;


-- Question 4
CREATE OR REPLACE PROCEDURE reserve_workstations(
    p_session_id INTEGER,
    p_lecturer VARCHAR,
    p_workstations INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT available_workstations INTO v_available
    FROM lab_sessions WHERE session_id = p_session_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Session ID % does not exist.', p_session_id;
    END IF;
    
    IF p_workstations <= 0 THEN
        RAISE EXCEPTION 'Workstations must be greater than zero.';
    END IF;
    
    IF v_available >= p_workstations THEN
        UPDATE lab_sessions
        SET available_workstations = available_workstations - p_workstations
        WHERE session_id = p_session_id;
        
        INSERT INTO reservations (session_id, lecturer, workstations, status)
        VALUES (p_session_id, p_lecturer, p_workstations, 'ACTIVE');
        
        RAISE NOTICE 'Reservation confirmed: % workstations for % in session %.',
            p_workstations, p_lecturer, p_session_id;
    ELSE
        RAISE EXCEPTION 'Insufficient workstations. Available: %, Requested: %',
            v_available, p_workstations;
    END IF;
END;
$$;


-- Question 5
CALL reserve_workstations(4, 'Dr. Jumbe', 1);
CALL reserve_workstations(2, 'Prof. Mwale', 1);
CALL reserve_workstations(2, 'Dr. Phiri', 10);  -- Exceeds capacity

SELECT * FROM lab_sessions;
SELECT * FROM reservations;



-- Question 6
CREATE OR REPLACE PROCEDURE cancel_reservation(p_reservation_id INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_session_id INTEGER;
    v_workstations INTEGER;
BEGIN
    SELECT status, session_id, workstations
    INTO v_status, v_session_id, v_workstations
    FROM reservations WHERE reservation_id = p_reservation_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reservation ID % does not exist.', p_reservation_id;
    END IF;
    
    IF v_status = 'ACTIVE' THEN
        UPDATE reservations
        SET status = 'CANCELLED'
        WHERE reservation_id = p_reservation_id;
        
        UPDATE lab_sessions
        SET available_workstations = available_workstations + v_workstations
        WHERE session_id = v_session_id;
        
        RAISE NOTICE 'Reservation % cancelled. % workstations released.',
            p_reservation_id, v_workstations;
    ELSE
        RAISE NOTICE 'Reservation % already cancelled. No workstations released.',
            p_reservation_id;
    END IF;
END;
$$;

CALL cancel_reservation(1);
CALL cancel_reservation(1);  -- Should NOT release again


-- Question 7
DO $$
DECLARE
    cur_few CURSOR FOR
        SELECT session_id, session_name, available_workstations
        FROM lab_sessions
        WHERE available_workstations <= 5
        ORDER BY available_workstations;
    
    v_id INTEGER;
    v_name VARCHAR(80);
    v_avail INTEGER;
BEGIN
    RAISE NOTICE '--- Sessions with Few Workstations ---';
    OPEN cur_few;
    LOOP
        FETCH cur_few INTO v_id, v_name, v_avail;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Session ID: %, Name: %, Available: %', v_id, v_name, v_avail;
    END LOOP;
    CLOSE cur_few;
END $$ LANGUAGE plpgsql;


-- Question 8
DO $$
BEGIN
    CALL reserve_workstations(1, 'Dr. Minion', 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error caught: %', SQLERRM;
END $$ LANGUAGE plpgsql;



-- Question 9
SELECT * FROM lab_sessions ORDER BY session_id;
SELECT * FROM reservations ORDER BY reservation_id;



