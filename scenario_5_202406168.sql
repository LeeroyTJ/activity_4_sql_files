-- Question 1
DROP TABLE IF EXISTS tool_loans;
DROP TABLE IF EXISTS tools;

CREATE TABLE tools (
    tool_id SERIAL PRIMARY KEY,
    tool_name VARCHAR(80) NOT NULL,
    available_quantity INTEGER NOT NULL CHECK (available_quantity >= 0)
);

CREATE TABLE tool_loans (
    loan_id SERIAL PRIMARY KEY,
    tool_id INTEGER REFERENCES tools(tool_id),
    student_number VARCHAR(20) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    status VARCHAR(20) DEFAULT 'LOANED'
);

INSERT INTO tools (tool_name, available_quantity) VALUES
('Hammer', 10),
('Screwdriver Set', 3),
('Electric Drill', 0);


-- Question 2
DO $$
DECLARE
    v_qty INTEGER;
    v_name VARCHAR(80);
BEGIN
    SELECT tool_name, available_quantity INTO v_name, v_qty
    FROM tools WHERE tool_id = 2;
    
    IF v_qty = 0 THEN
        RAISE NOTICE 'Tool "%" is UNAVAILABLE.', v_name;
    ELSIF v_qty <= 3 THEN
        RAISE NOTICE 'Tool "%" is LOW ON STOCK (% remaining).', v_name, v_qty;
    ELSE
        RAISE NOTICE 'Tool "%" is READILY AVAILABLE (% units).', v_name, v_qty;
    END IF;
END $$ LANGUAGE plpgsql;



-- Question 3
DO $$
DECLARE
    v_counter INTEGER := 1;
BEGIN
    RAISE NOTICE '--- Workshop Safety Reminders ---';
    WHILE v_counter <= 3 LOOP
        RAISE NOTICE 'Safety Reminder #%', v_counter;
        v_counter := v_counter + 1;
    END LOOP;
    
    RAISE NOTICE '--- Tool Inspections ---';
    FOR i IN 1..3 LOOP
        RAISE NOTICE 'Tool Inspection #%', i;
    END LOOP;
END $$ LANGUAGE plpgsql;



-- Question 4
CREATE OR REPLACE PROCEDURE issue_tool(
    p_tool_id INTEGER,
    p_student_number VARCHAR,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INTEGER;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero.';
    END IF;
    
    SELECT available_quantity INTO v_available
    FROM tools WHERE tool_id = p_tool_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tool ID % does not exist.', p_tool_id;
    END IF;
    
    IF v_available >= p_quantity THEN
        UPDATE tools
        SET available_quantity = available_quantity - p_quantity
        WHERE tool_id = p_tool_id;
        
        INSERT INTO tool_loans (tool_id, student_number, quantity, status)
        VALUES (p_tool_id, p_student_number, p_quantity, 'LOANED');
        
        RAISE NOTICE 'Tool % issued: % unit(s) to student %.',
            p_tool_id, p_quantity, p_student_number;
    ELSE
        RAISE EXCEPTION 'Insufficient stock. Available: %, Requested: %',
            v_available, p_quantity;
    END IF;
END;
$$;



-- Question 5
CALL issue_tool(1, '2024010001', 3);
CALL issue_tool(2, '2024010002', 1);
CALL issue_tool(2, '2024010003', 10);  -- Exceeds stock

SELECT * FROM tools;
SELECT * FROM tool_loans;


-- Question 6
CREATE OR REPLACE PROCEDURE return_tool(p_loan_id INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_tool_id INTEGER;
    v_quantity INTEGER;
BEGIN
    SELECT status, tool_id, quantity
    INTO v_status, v_tool_id, v_quantity
    FROM tool_loans WHERE loan_id = p_loan_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Loan ID % does not exist.', p_loan_id;
    END IF;
    
    IF v_status = 'LOANED' THEN
        UPDATE tool_loans
        SET status = 'RETURNED'
        WHERE loan_id = p_loan_id;
        
        UPDATE tools
        SET available_quantity = available_quantity + v_quantity
        WHERE tool_id = v_tool_id;
        
        RAISE NOTICE 'Loan % returned. % unit(s) restored.', p_loan_id, v_quantity;
    ELSE
        RAISE NOTICE 'Loan % already returned. No stock added.', p_loan_id;
    END IF;
END;
$$;

CALL return_tool(1);
CALL return_tool(1);  -- Should NOT add stock again


-- Question 7
DO $$
DECLARE
    cur_low CURSOR FOR
        SELECT tool_id, tool_name, available_quantity
        FROM tools
        WHERE available_quantity <= 3
        ORDER BY available_quantity;
    
    v_id INTEGER;
    v_name VARCHAR(80);
    v_qty INTEGER;
BEGIN
    RAISE NOTICE '--- Tools with Low Availability ---';
    OPEN cur_low;
    LOOP
        FETCH cur_low INTO v_id, v_name, v_qty;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'ID: %, Name: %, Available: %', v_id, v_name, v_qty;
    END LOOP;
    CLOSE cur_low;
END $$ LANGUAGE plpgsql;



-- Question 8
DO $$
BEGIN
    CALL issue_tool(1, '2024010005', 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error caught: %', SQLERRM;
END $$ LANGUAGE plpgsql;



-- Question 9
SELECT * FROM tools ORDER BY tool_id;
SELECT * FROM tool_loans ORDER BY loan_id;












