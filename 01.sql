CREATE TABLE TIME (
    ID_TIME NUMBER(3) PRIMARY KEY,
    MONTH   NUMBER(2),
    YEAR    NUMBER(4)
);

CREATE TABLE ZIP (
    ID_ZIP  NUMBER(4) PRIMARY KEY,
    ZIPCODE VARCHAR2(5),
    STATE   VARCHAR2(2)
);

DESC CUSTOMERS;

CREATE TABLE SALE (
    ID_SALE NUMBER PRIMARY KEY,
    ID_TIME NUMBER(3) REFERENCES TIME(ID_TIME),
    ID_ZIP  NUMBER(4) REFERENCES ZIP(ID_ZIP),
    AMOUNT  NUMBER
);

CREATE SEQUENCE S_TIME;
CREATE SEQUENCE S_ZIP;
CREATE SEQUENCE S_SALE;

CREATE OR REPLACE TRIGGER T_SET_ID_TIME
    BEFORE INSERT ON TIME
    FOR EACH ROW BEGIN
        :NEW.ID_TIME := S_TIME.NEXTVAL;
    END;
/
    
CREATE OR REPLACE TRIGGER T_SET_ID_ZIP
    BEFORE INSERT ON ZIP
    FOR EACH ROW BEGIN
        :NEW.ID_ZIP := S_ZIP.NEXTVAL;
    END;
/

    
CREATE OR REPLACE TRIGGER T_SET_ID_SALE
    BEFORE INSERT ON SALE
    FOR EACH ROW BEGIN
        :NEW.ID_SALE := S_SALE.NEXTVAL;
    END;
/

CREATE OR REPLACE PROCEDURE P_LOAD_DATA 
    IS BEGIN
        INSERT INTO TIME (MONTH, YEAR)
            SELECT 
                EXTRACT(MONTH FROM ORDERDATE), 
                EXTRACT(YEAR FROM ORDERDATE)
            FROM ORDERS
            GROUP BY 
                EXTRACT(MONTH FROM ORDERDATE), 
                EXTRACT(YEAR FROM ORDERDATE)
            ORDER BY 2, 1;
            
        INSERT INTO ZIP (ZIPCODE, STATE)
            SELECT DISTINCT ZIP, STATE
            FROM CUSTOMERS
            ORDER BY 2, 1;
            
        INSERT INTO SALE (ID_TIME, ID_ZIP, AMOUNT)
            SELECT T.ID_TIME, Z.ID_ZIP, SUM(OI.QUANTITY * B.RETAIL)
            FROM BOOKS B 
                JOIN ORDERITEMS OI
                ON B.ISBN = OI.ISBN
                    JOIN ORDERS O
                    ON OI.ORDER# = O.ORDER#
                        JOIN CUSTOMERS C
                        ON O.CUSTOMER# = C.CUSTOMER#
                            JOIN ZIP Z 
                            ON Z.ZIPCODE = C.ZIP
                                JOIN TIME T
                                ON T.MONTH = EXTRACT(MONTH FROM O.ORDERDATE)
                                AND T.YEAR = EXTRACT(YEAR FROM O.ORDERDATE)
            GROUP BY T.ID_TIME, Z.ID_ZIP;
    END;
/

EXECUTE P_LOAD_DATA;

SELECT * FROM TIME;

CREATE OR REPLACE FUNCTION F_CALCULATE_PROFIT (P_STATE ORDERS.SHIPSTATE%TYPE)
    RETURN NUMBER
    AS
        V_PROFIT NUMBER;
    BEGIN
        SELECT SUM(OI.QUANTITY * (B.RETAIL - B.COST))
        INTO V_PROFIT
        FROM BOOKS B
            JOIN ORDERITEMS OI
            ON B.ISBN = OI.ISBN
                JOIN ORDERS O
                ON OI.ORDER# = O.ORDER#
        WHERE O.SHIPSTATE = P_STATE;
        
        RETURN V_PROFIT;
    END;
/
    
SELECT DISTINCT SHIPSTATE, F_CALCULATE_PROFIT(SHIPSTATE)
FROM ORDERS;

SELECT F_CALCULATE_PROFIT('FL') 
FROM DUAL;