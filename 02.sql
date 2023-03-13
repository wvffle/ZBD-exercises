-- CREATE OR REPLACE FUNCTION F_SALE_BY_ZIP_TIME (
--     P_ZIPCODE CUSTOMERS.ZIP%TYPE, 
--     P_MONTH NUMBER, 
--     P_YEAR NUMBER
-- )
--     RETURN NUMBER
--     AS
--         V_SALE NUMBER;
--     BEGIN
--         SELECT SUM(OI.QUANTITY * B.RETAIL)
--             INTO V_SALE
--             FROM BOOKS B
--                 JOIN ORDERITEMS OI
--                 ON OI.ISBN = B.ISBN
--                     JOIN ORDERS O
--                     ON OI.ORDER# = O.ORDER#
--                         JOIN CUSTOMERS C
--                         ON O.CUSTOMER# = C.CUSTOMER#
--             WHERE C.ZIP = P_ZIPCODE
--                 AND EXTRACT(MONTH FROM O.ORDERDATE) = P_MONTH
--                 AND EXTRACT(YEAR FROM O.ORDERDATE) = P_YEAR;
                            
--         RETURN V_SALE;
--     END;
-- /

-- CREATE OR REPLACE PROCEDURE P_APPEND_DATA AS
--     BEGIN
--         MERGE INTO ZIP Z
--             USING (
--                 SELECT DISTINCT 
--                     ZIP, 
--                     STATE 
--                 FROM CUSTOMERS
--             ) SUB
--             ON (Z.ZIPCODE = SUB.ZIP)
            
--             WHEN NOT MATCHED THEN
--                 INSERT (ZIPCODE, STATE)
--                     VALUES (SUB.ZIP, SUB.STATE);
                    
--         MERGE INTO TIME T
--             USING (
--                 SELECT DISTINCT
--                     EXTRACT(MONTH FROM ORDERDATE) MONTH,
--                     EXTRACT(YEAR FROM ORDERDATE) YEAR
--                 FROM ORDERS
--             ) SUB
--             ON (T.MONTH = SUB.MONTH AND T.YEAR = SUB.YEAR)
--             WHEN NOT MATCHED THEN
--                 INSERT (MONTH, YEAR)
--                     VALUES (SUB.MONTH, SUB.YEAR);

                    
--         MERGE INTO SALE S
--             USING (
--                 SELECT DISTINCT
--                     T.ID_TIME,
--                     Z.ID_ZIP,
--                     F_SALE_BY_ZIP_TIME(Z.ZIPCODE, T.MONTH, T.YEAR) AMOUNT
--                 FROM 
--                     ZIP Z, 
--                     TIME T, 
--                     CUSTOMERS C, 
--                     ORDERS O
--                 WHERE C.CUSTOMER# = O.CUSTOMER#
--                     AND C.ZIP = Z.ZIPCODE
--                     AND EXTRACT(MONTH FROM O.ORDERDATE) = T.MONTH
--                     AND EXTRACT(YEAR FROM O.ORDERDATE) = T.YEAR
--             ) SUB
--             ON (S.ID_TIME = SUB.ID_TIME AND S.ID_ZIP = SUB.ID_ZIP)
--             WHEN NOT MATCHED THEN
--                 INSERT (ID_TIME, ID_ZIP, AMOUNT)
--                     VALUES (SUB.ID_TIME, SUB.ID_ZIP, SUB.AMOUNT);

--     END;
-- /

CREATE OR REPLACE PACKAGE PACKAGE_DATA_MIGRATION
    AS
    
        FUNCTION F_SALE_BY_ZIP_TIME (
            P_ZIPCODE CUSTOMERS.ZIP%TYPE,
            P_MONTH NUMBER,
            P_YEAR NUMBER
        )
            RETURN NUMBER;
        
        PROCEDURE P_APPEND_DATA;
    END;
/


CREATE OR REPLACE PACKAGE BODY PACKAGE_DATA_MIGRATION
    AS
        FUNCTION F_SALE_BY_ZIP_TIME (
            P_ZIPCODE CUSTOMERS.ZIP%TYPE, 
            P_MONTH NUMBER, 
            P_YEAR NUMBER
        )
            RETURN NUMBER
            AS
                V_SALE NUMBER;
            BEGIN
                SELECT SUM(OI.QUANTITY * B.RETAIL)
                    INTO V_SALE
                    FROM BOOKS B
                        JOIN ORDERITEMS OI
                        ON OI.ISBN = B.ISBN
                            JOIN ORDERS O
                            ON OI.ORDER# = O.ORDER#
                                JOIN CUSTOMERS C
                                ON O.CUSTOMER# = C.CUSTOMER#
                    WHERE C.ZIP = P_ZIPCODE
                        AND EXTRACT(MONTH FROM O.ORDERDATE) = P_MONTH
                        AND EXTRACT(YEAR FROM O.ORDERDATE) = P_YEAR;
                                    
                RETURN V_SALE;
            END;

        PROCEDURE P_APPEND_DATA AS
            BEGIN
                MERGE INTO ZIP Z
                    USING (
                        SELECT DISTINCT 
                            ZIP, 
                            STATE 
                        FROM CUSTOMERS
                    ) SUB
                    ON (Z.ZIPCODE = SUB.ZIP)
                    
                    WHEN NOT MATCHED THEN
                        INSERT (ZIPCODE, STATE)
                            VALUES (SUB.ZIP, SUB.STATE);
                            
                MERGE INTO TIME T
                    USING (
                        SELECT DISTINCT
                            EXTRACT(MONTH FROM ORDERDATE) MONTH,
                            EXTRACT(YEAR FROM ORDERDATE) YEAR
                        FROM ORDERS
                    ) SUB
                    ON (T.MONTH = SUB.MONTH AND T.YEAR = SUB.YEAR)
                    WHEN NOT MATCHED THEN
                        INSERT (MONTH, YEAR)
                            VALUES (SUB.MONTH, SUB.YEAR);

                            
                MERGE INTO SALE S
                    USING (
                        SELECT DISTINCT
                            T.ID_TIME,
                            Z.ID_ZIP,
                            F_SALE_BY_ZIP_TIME(Z.ZIPCODE, T.MONTH, T.YEAR) AMOUNT
                        FROM 
                            ZIP Z, 
                            TIME T, 
                            CUSTOMERS C, 
                            ORDERS O
                        WHERE C.CUSTOMER# = O.CUSTOMER#
                            AND C.ZIP = Z.ZIPCODE
                            AND EXTRACT(MONTH FROM O.ORDERDATE) = T.MONTH
                            AND EXTRACT(YEAR FROM O.ORDERDATE) = T.YEAR
                    ) SUB
                    ON (S.ID_TIME = SUB.ID_TIME AND S.ID_ZIP = SUB.ID_ZIP)
                    WHEN NOT MATCHED THEN
                        INSERT (ID_TIME, ID_ZIP, AMOUNT)
                            VALUES (SUB.ID_TIME, SUB.ID_ZIP, SUB.AMOUNT);

            END;
END PACKAGE_DATA_MIGRATION;

EXECUTE PACKAGE_DATA_MIGRATION.P_APPEND_DATA;

CREATE OR REPLACE TRIGGER T_CONTROL_RETAIL
    BEFORE INSERT OR UPDATE OF RETAIL
        ON BOOKS

    FOR EACH ROW BEGIN
        IF :NEW.RETAIL > :NEW.CONST * 2 THEN
            :NEW.RETAIL := :NEW.CONST * 2;
        END IF;
    END;
/

UPDATE BOOKS
    SET RETAIL = COST * 3;