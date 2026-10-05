-- Question 1
DROP TABLE IF EXISTS allocations;
DROP TABLE IF EXISTS hostel_rooms;

CREATE TABLE hostel_rooms (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(10) NOT NULL,
    available_spaces INTEGER NOT NULL CHECK (available_spaces >= 0)
);

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    room_id INTEGER REFERENCES hostel_rooms(room_id),
    status VARCHAR(20) DEFAULT 'ACTIVE'
);

INSERT INTO hostel_rooms (room_number, available_spaces) VALUES
('A101', 4),
('B202', 1),
('C303', 0);


-- Question 2
DO $$
DECLARE
    v_spaces INTEGER;
    v_room VARCHAR(10);
BEGIN
    SELECT room_number, available_spaces INTO v_room, v_spaces
    FROM hostel_rooms WHERE room_id = 2;
    
    IF v_spaces = 0 THEN
        RAISE NOTICE 'Room "%" is FULL.', v_room;
    ELSIF v_spaces = 1 THEN
        RAISE NOTICE 'Room "%" has ONE space left.', v_room;
    ELSE
        RAISE NOTICE 'Room "%" has SEVERAL spaces (% available).', v_room, v_spaces;
    END IF;
END $$ LANGUAGE plpgsql;



-- Question 3
DO $$
DECLARE
    v_counter INTEGER := 1;
BEGIN
    RAISE NOTICE '--- Hostel Inspection Days ---';
    WHILE v_counter <= 3 LOOP
        RAISE NOTICE 'Inspection Day #%', v_counter;
        v_counter := v_counter + 1;
    END LOOP;
    
    RAISE NOTICE '--- Room Checks ---';
    FOR i IN 1..3 LOOP
        RAISE NOTICE 'Room Check #%', i;
    END LOOP;
END $$ LANGUAGE plpgsql;


-- Question 4
CREATE OR REPLACE PROCEDURE allocate_room(
    p_student_number VARCHAR,
    p_room_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_spaces INTEGER;
BEGIN
    -- Validate student number
    IF p_student_number IS NULL OR TRIM(p_student_number) = '' THEN
        RAISE EXCEPTION 'Student number cannot be blank.';
    END IF;
    
    SELECT available_spaces INTO v_spaces
    FROM hostel_rooms WHERE room_id = p_room_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Room ID % does not exist.', p_room_id;
    END IF;
    
    IF v_spaces >= 1 THEN
        UPDATE hostel_rooms
        SET available_spaces = available_spaces - 1
        WHERE room_id = p_room_id;
        
        INSERT INTO allocations (student_number, room_id, status)
        VALUES (p_student_number, p_room_id, 'ACTIVE');
        
        RAISE NOTICE 'Room % allocated to student %.', p_room_id, p_student_number;
    ELSE
        RAISE EXCEPTION 'Room % is FULL. No spaces available.', p_room_id;
    END IF;
END;
$$;


-- Question 5
CALL allocate_room('2024010001', 1);
CALL allocate_room('2024010002', 1);
CALL allocate_room('2024010003', 3);  -- Full room

SELECT * FROM hostel_rooms;
SELECT * FROM allocations;



-- Question 6
CREATE OR REPLACE PROCEDURE check_out(p_allocation_id INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_room_id INTEGER;
BEGIN
    SELECT status, room_id INTO v_status, v_room_id
    FROM allocations WHERE allocation_id = p_allocation_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Allocation ID % does not exist.', p_allocation_id;
    END IF;
    
    IF v_status = 'ACTIVE' THEN
        UPDATE allocations
        SET status = 'COMPLETE'
        WHERE allocation_id = p_allocation_id;
        
        UPDATE hostel_rooms
        SET available_spaces = available_spaces + 1
        WHERE room_id = v_room_id;
        
        RAISE NOTICE 'Allocation % checked out. One space released.', p_allocation_id;
    ELSE
        RAISE NOTICE 'Allocation % already complete. No space released.', p_allocation_id;
    END IF;
END;
$$;

CALL check_out(1);
CALL check_out(1);  -- Should NOT release again


-- Question 7
DO $$
DECLARE
    cur_full CURSOR FOR
        SELECT room_id, room_number, available_spaces
        FROM hostel_rooms
        WHERE available_spaces <= 1
        ORDER BY available_spaces;
    
    v_id INTEGER;
    v_num VARCHAR(10);
    v_spaces INTEGER;
BEGIN
    RAISE NOTICE '--- Full or Nearly Full Rooms ---';
    OPEN cur_full;
    LOOP
        FETCH cur_full INTO v_id, v_num, v_spaces;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Room ID: %, Number: %, Spaces: %', v_id, v_num, v_spaces;
    END LOOP;
    CLOSE cur_full;
END $$ LANGUAGE plpgsql;



-- Question 8
DO $$
BEGIN
    CALL allocate_room('', 1);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error caught: %', SQLERRM;
END $$ LANGUAGE plpgsql;


-- Question 9
SELECT * FROM hostel_rooms ORDER BY room_id;
SELECT * FROM allocations ORDER BY allocation_id;

















