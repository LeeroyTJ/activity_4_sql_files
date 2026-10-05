-- Question 1

DROP TABLE IF EXISTS book_loans;
DROP TABLE IF EXISTS books;


CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    author VARCHAR(80),
    available_copies INTEGER NOT NULL CHECK (available_copies >= 0)
);


CREATE TABLE book_loans (
    loan_id SERIAL PRIMARY KEY,
    book_id INTEGER REFERENCES books(book_id),
    student_number VARCHAR(20) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    loan_status VARCHAR(20) DEFAULT 'ACTIVE'
);

-- Insert at least three books
INSERT INTO books (title, author, available_copies) VALUES
('Concrete Mathematics: A Foundation for Computer Science', 'Ronald L. Graham', 5),
('Introduction to Algorithms', 'Thomas H. Cormen', 2),
('Discrete Mathematics and Its Applications', 'Kenneth H. Rosen', 0);


SELECT * FROM books;


-- Question 2

DO $$
DECLARE
    v_copies INTEGER;
    v_title VARCHAR(100);
BEGIN
    SELECT title, available_copies INTO v_title, v_copies
    FROM books WHERE book_id = 2;
    
    IF v_copies = 0 THEN
        RAISE NOTICE 'Book "%" is UNAVAILABLE (0 copies).', v_title;
    ELSIF v_copies <= 2 THEN
        RAISE NOTICE 'Book "%" is LOW ON COPIES (% remaining).', v_title, v_copies;
    ELSE
        RAISE NOTICE 'Book "%" is SUFFICIENTLY STOCKED (% copies).', v_title, v_copies;
    END IF;
END $$ LANGUAGE plpgsql;


-- Question 3

DO $$
DECLARE
    v_counter INTEGER := 1;
BEGIN
    -- 3 overdue reminder numbers
    RAISE NOTICE '--- Overdue Reminders ---';
    WHILE v_counter <= 3 LOOP
        RAISE NOTICE 'Overdue Reminder #%', v_counter;
        v_counter := v_counter + 1;
    END LOOP;
    
    -- 3 library shelf numbers
    RAISE NOTICE '--- Library Shelf Numbers ---';
    FOR i IN 1..3 LOOP
        RAISE NOTICE 'Shelf #%', i;
    END LOOP;
END $$ LANGUAGE plpgsql;



-- Question 4

CREATE OR REPLACE PROCEDURE borrow_book(
    p_book_id INTEGER,
    p_student_number VARCHAR,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INTEGER;
BEGIN
    -- Check available copies
    SELECT available_copies INTO v_available
    FROM books WHERE book_id = p_book_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Book ID % does not exist.', p_book_id;
    END IF;
    
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero.';
    END IF;
    
    -- Check stock
    IF v_available >= p_quantity THEN
        -- Reduce stock
        UPDATE books
        SET available_copies = available_copies - p_quantity
        WHERE book_id = p_book_id;
        
        -- Record loan
        INSERT INTO book_loans (book_id, student_number, quantity, loan_status)
        VALUES (p_book_id, p_student_number, p_quantity, 'ACTIVE');
        
        RAISE NOTICE 'Loan recorded: % copies of book % to student %.',
            p_quantity, p_book_id, p_student_number;
    ELSE
        RAISE EXCEPTION 'Insufficient copies. Available: %, Requested: %',
            v_available, p_quantity;
    END IF;
END;
$$;


-- Question 5

-- Call for two valid loans
CALL borrow_book(1, '2024010001', 2);
CALL borrow_book(2, '2024010002', 1);

-- One request exceeding available copies
CALL borrow_book(2, '2024010003', 5);

-- Query both tables
SELECT * FROM books;
SELECT * FROM book_loans;



-- Question 6

CREATE OR REPLACE PROCEDURE return_book(p_loan_id INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_book_id INTEGER;
    v_quantity INTEGER;
BEGIN
    SELECT loan_status, book_id, quantity
    INTO v_status, v_book_id, v_quantity
    FROM book_loans WHERE loan_id = p_loan_id;
    
    -- Check if loan exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Loan ID % does not exist.', p_loan_id;
    END IF;
    
    IF v_status = 'ACTIVE' THEN
        -- Mark loan as RETURNED
        UPDATE book_loans
        SET loan_status = 'RETURNED'
        WHERE loan_id = p_loan_id;
        
        -- Restore copies
        UPDATE books
        SET available_copies = available_copies + v_quantity
        WHERE book_id = v_book_id;
        
        RAISE NOTICE 'Loan % returned. % copies restored.', p_loan_id, v_quantity;
    ELSE
        RAISE NOTICE 'Loan % already returned. No copies restored.', p_loan_id;
    END IF;
END;
$$;

CALL return_book(1);
CALL return_book(1);



-- Question 7

DO $$
DECLARE
    -- Declare cursor
    cur_low_stock CURSOR FOR
        SELECT book_id, title, available_copies
        FROM books
        WHERE available_copies <= 2
        ORDER BY available_copies;
    
    v_book_id INTEGER;
    v_title VARCHAR(100);
    v_copies INTEGER;
BEGIN
    RAISE NOTICE '--- Books with Few Copies ---';
    
    OPEN cur_low_stock;
    LOOP
        FETCH cur_low_stock INTO v_book_id, v_title, v_copies;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Book ID: %, Title: %, Copies: %',
            v_book_id, v_title, v_copies;
    END LOOP;
    CLOSE cur_low_stock;
END $$ LANGUAGE plpgsql;


-- Question 8

DO $$
BEGIN
    -- Try to borrow zero copies
    CALL borrow_book(1, '2024010004', 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error caught: %', SQLERRM;
END $$ LANGUAGE plpgsql;


-- Question 9

SELECT * FROM books ORDER BY book_id;
SELECT * FROM book_loans ORDER BY loan_id;









