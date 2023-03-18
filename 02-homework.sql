SELECT * from SLOWIKOWSKA_MONIKA.TEMP;

-- 02

CREATE TABLE PRODUCTS_02 (
    PRODUCT#    NUMBER      PRIMARY KEY,
    STOCKCODE   VARCHAR2(32),
    DESCRIPTION VARCHAR2(512),
    UNITPRICE   NUMBER
);

CREATE TABLE COUNTRIES_02 (
    COUNTRY#    NUMBER    PRIMARY KEY,
    NAME        VARCHAR2(512)
);

CREATE TABLE CUSTOMERS_02 (
    CUSTOMER#   NUMBER  PRIMARY KEY,
    CUSTOMERID  NUMBER,
    COUNTRY     NUMBER  REFERENCES COUNTRIES_02(COUNTRY#)
);

CREATE TABLE ORDERS_02 (
    ORDER#      NUMBER  PRIMARY KEY,
    INVOICENO   VARCHAR2(32),
    INVOICEDATE DATE,
    CUSTOMER    NUMBER  REFERENCES CUSTOMERS_02(CUSTOMER#)
);

CREATE TABLE ORDERITEMS_02 (
    ORDER#      NUMBER REFERENCES ORDERS_02(ORDER#),
    PRODUCT#    NUMBER REFERENCES PRODUCTS_02(PRODUCT#),
    QUANTITY    NUMBER
);

-- 03

CREATE SEQUENCE S_PRODUCTS_02;
CREATE SEQUENCE S_COUNTRIES_02;
CREATE SEQUENCE S_CUSTOMERS_02;
CREATE SEQUENCE S_ORDERS_02;

CREATE OR REPLACE TRIGGER T_SET_ID_PRODUCTS_02
    BEFORE INSERT ON PRODUCTS_02
    FOR EACH ROW BEGIN
        :NEW.PRODUCT# := S_PRODUCTS_02.NEXTVAL;
    END;
/

CREATE OR REPLACE TRIGGER T_SET_ID_COUNTRIES_02
    BEFORE INSERT ON COUNTRIES_02
    FOR EACH ROW BEGIN
        :NEW.COUNTRY# := S_COUNTRIES_02.NEXTVAL;
    END;
/

CREATE OR REPLACE TRIGGER T_SET_ID_CUSTOMERS_02
    BEFORE INSERT ON CUSTOMERS_02
    FOR EACH ROW BEGIN
        :NEW.CUSTOMER# := S_CUSTOMERS_02.NEXTVAL;
    END;
/

CREATE OR REPLACE TRIGGER T_SET_ID_ORDERS_02
    BEFORE INSERT ON ORDERS_02
    FOR EACH ROW BEGIN
        :NEW.ORDER# := S_ORDERS_02.NEXTVAL;
    END;
/

-- 04

CREATE OR REPLACE PACKAGE PACKAGE_TEMP 
    AS
        PROCEDURE P_MIGRATE;

        FUNCTION F_SALE_FOR_COUNTRY (
            P_COUNTRY_NAME COUNTRIES_02.NAME%TYPE
        )
            RETURN NUMBER;
    END;
/

CREATE OR REPLACE PACKAGE BODY PACKAGE_TEMP 
    AS
        PROCEDURE P_MIGRATE AS
            BEGIN
                MERGE INTO PRODUCTS_02 P
                    USING (
                        SELECT DISTINCT
                            STOCKCODE,
                            DESCRIPTION,
                            UNITPRICE
                        FROM SLOWIKOWSKA_MONIKA.TEMP
                    ) SUB
                    ON (P.STOCKCODE = SUB.STOCKCODE)
                    
                    WHEN NOT MATCHED THEN
                        INSERT (STOCKCODE, DESCRIPTION, UNITPRICE)
                            VALUES (SUB.STOCKCODE, SUB.DESCRIPTION, SUB.UNITPRICE);

                MERGE INTO COUNTRIES_02 C
                    USING (
                        SELECT DISTINCT
                            COUNTRY
                        FROM SLOWIKOWSKA_MONIKA.TEMP
                    ) SUB
                    ON (C.NAME = SUB.COUNTRY)
                    
                    WHEN NOT MATCHED THEN
                        INSERT (NAME)
                            VALUES (SUB.COUNTRY);

                MERGE INTO CUSTOMERS_02 C
                    USING (
                        SELECT DISTINCT
                            T.CUSTOMERID, 
                            Q.COUNTRY#
                        FROM SLOWIKOWSKA_MONIKA.TEMP T, COUNTRIES_02 Q
                        WHERE T.COUNTRY = Q.NAME
                    ) SUB
                    ON (C.CUSTOMERID = SUB.CUSTOMERID)
                    
                    WHEN NOT MATCHED THEN
                        INSERT (CUSTOMERID, COUNTRY)
                            VALUES (SUB.CUSTOMERID, SUB.COUNTRY#);


                MERGE INTO ORDERS_02 O
                    USING (
                        SELECT DISTINCT
                            T.INVOICENO, 
                            T.INVOICEDATE,
                            C.CUSTOMER#
                        FROM SLOWIKOWSKA_MONIKA.TEMP T, CUSTOMERS_02 C
                        WHERE C.CUSTOMERID = T.CUSTOMERID
                    ) SUB
                    ON (O.INVOICENO = SUB.INVOICENO)
                    
                    WHEN NOT MATCHED THEN
                        INSERT (INVOICENO, INVOICEDATE, CUSTOMER)
                            VALUES (SUB.INVOICENO, SUB.INVOICEDATE, SUB.CUSTOMER#);

                MERGE INTO ORDERITEMS_02 OI
                    USING (
                        SELECT DISTINCT
                            O.ORDER#,
                            P.PRODUCT#,
                            T.QUANTITY
                        FROM SLOWIKOWSKA_MONIKA.TEMP T, ORDERS_02 O, PRODUCTS_02 P
                        WHERE T.INVOICENO = O.INVOICENO AND P.STOCKCODE = T.STOCKCODE
                    ) SUB
                    ON (OI.ORDER# = SUB.ORDER# AND OI.PRODUCT# = SUB.PRODUCT#)
                    
                    WHEN NOT MATCHED THEN
                        INSERT (ORDER#, PRODUCT#, QUANTITY)
                            VALUES (SUB.ORDER#, SUB.PRODUCT#, SUB.QUANTITY);

            END;

        FUNCTION F_SALE_FOR_COUNTRY (
            P_COUNTRY_NAME COUNTRIES_02.NAME%TYPE
        ) 
            RETURN NUMBER
            AS
                V_SALE NUMBER;
            BEGIN
                RETURN V_SALE;
            END; 
    END;
/



select distinct Q.CUSTOMERID, P.COUNTRY FROM
SLOWIKOWSKA_MONIKA.TEMP P,
(select CUSTOMERID, count(distinct country) A from SLOWIKOWSKA_MONIKA.TEMP group by CUSTOMERID order by A desc) Q
where Q.A > 1 and Q.CUSTOMERID = P.CUSTOMERID order by Q.CUSTOMERID;


select customerid, count(customerid) A from CUSTOMERS_02 group by customerid order by A DESC;