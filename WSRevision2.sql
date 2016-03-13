/* Q1 */
SELECT TO_CHAR(SYSTIMESTAMP, 'DD-MM-YYYY HH24:MI:SS TZH:TZM') "Time & Date & Timezone"
FROM DUAL;

/* Q2 */
SELECT *
FROM gv$timezone_names;

/* Q3 */
SELECT TO_CHAR(SYSTIMESTAMP AT TIME ZONE 'EUROPE/MALTA','DD-MM-YYYY HH24:MI:SS TZH:TZM') "Local Time and Date & Timezone"
FROM DUAL;

/* Q4 */
SELECT 1 AS "Q4"
FROM DUAL;

/* Q5 */
SELECT (CASE WHEN 50 > 0 AND 50 <= 500 THEN 1 ELSE 0 END) AS "Q5"
FROM DUAL;

/* Q6 TURN INTO IF */
CREATE OR REPLACE FUNCTION isValidAmount (p_amount IN tbl_payments.payment_amount%TYPE)
RETURN NUMBER IS 
	result NUMBER(1) := 0;
BEGIN 
	SELECT (CASE WHEN p_amount > 0 AND p_amount <= 500 THEN 1 ELSE 0 END) INTO result
	FROM DUAL;
	
	RETURN result;
END;

/* Q7 */
SELECT isValidAmount(-5) AS "Q7 Value : -5" 
FROM DUAL;

SELECT isValidAmount(0) AS "Q7 Value : 0" 
FROM DUAL;

SELECT isValidAmount(50) AS "Q7 Value : 50" 
FROM DUAL;

SELECT isValidAmount(500) AS "Q7 Value : 500" 
FROM DUAL;

/* Q8 */
SELECT * 
FROM tbl_account_status;

SELECT u.account_username AS "Username" 
FROM tbl_user_accounts u;

/* Q9 */
SELECT u.account_username AS "Username",
s.status_name AS "Status name"
FROM tbl_user_accounts u 
LEFT OUTER JOIN tbl_account_status s
ON u.status_id = s.status_id;

/* Q10 */
SELECT u.account_username AS "Username",
s.status_name AS "Status name"
FROM tbl_user_accounts u 
INNER JOIN tbl_account_status s
ON u.status_id = s.status_id
WHERE s.status_name = 'Active';

/* Q11 */
CREATE OR REPLACE FUNCTION getActiveUser
(a_username IN tbl_user_accounts.account_username%TYPE)
RETURN NUMBER
	IS result NUMBER(1);
BEGIN 
	SELECT COUNT(*) INTO result
	FROM tbl_user_accounts u
	INNER JOIN tbl_account_status s
	ON u.status_id = s.status_id 
	WHERE u.account_username = a_username AND s.status_name = 'Active';
	
	RETURN result;
END;

/* Q12 */
SELECT getActiveUser('lisag') AS "Q12"
FROM DUAL;

SELECT getActiveUser('joeb') AS "Q12"
FROM DUAL;

/* Q13 */
SELECT o.order_id AS "Order ID",
p.product_name AS "Product name",
p.unit_price AS "Unit price",
oi.quantity AS "Quantity"
FROM tbl_orders o 
INNER JOIN tbl_order_items oi
ON o.order_id = oi.order_id
INNER JOIN tbl_products p
ON p.product_id = oi.product_id;

/* Q14 */
SELECT SUM(p.unit_price * oi.quantity) AS "Order total price"
FROM tbl_orders o 
LEFT OUTER JOIN tbl_order_items oi
ON o.order_id = oi.order_id
LEFT OUTER JOIN tbl_products p
ON p.product_id = oi.product_id
WHERE o.order_id = 1;

/* Q15 */
CREATE OR REPLACE FUNCTION getOrderTotal
(p_order_id IN tbl_orders.order_id%TYPE)
RETURN NUMBER 
	IS total NUMBER(10,4);
BEGIN 
	SELECT SUM(p.unit_price * oi.quantity) INTO total
	FROM tbl_orders o
	INNER JOIN tbl_order_items oi 
	ON o.order_id = oi.order_id
	INNER JOIN tbl_products p 
	ON p.product_id = oi.product_id
	WHERE o.order_id = p_order_id;
	
	RETURN total;
END;

/* Q16 */
SELECT getOrderTotal(1) AS "Total Order 4100 "
FROM DUAL;

SELECT getOrderTotal(2) AS "Total Order 1225"
FROM DUAL;

SELECT getOrderTotal(3) AS "Total Order 3225"
FROM DUAL;

SELECT getOrderTotal(4) AS "Total Order 1600"
FROM DUAL;

/* Q17 */
CREATE SEQUENCE seq_payment_id
	START WITH     1000
	INCREMENT BY   1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOCYCLE;

/* Q18 */
CREATE OR REPLACE FUNCTION getOrderUsername 
(p_order_id IN tbl_orders.order_id%TYPE)
RETURN VARCHAR 
	IS username VARCHAR(32 CHAR);
BEGIN 
	SELECT a.account_username INTO username 
	FROM tbl_user_accounts a
	INNER JOIN tbl_orders o
	ON a.account_id  = o.account_id
	WHERE o.order_id = p_order_id;

	RETURN username;
END;

/* Q19 */
SELECT o.order_id AS "Order ID",
getOrderUsername(o.order_id) AS "Username",
(CASE WHEN getActiveUser(getOrderUsername(o.order_id)) = 1 THEN 'Yes' ELSE 'NO' END) AS "Is active"
FROM tbl_orders o;

/* Q20 (Added an extra function : checkOrderExist) */
CREATE OR REPLACE FUNCTION checkOrderExist
(p_order_id IN tbl_orders.order_id%TYPE)
RETURN NUMBER 
	IS result NUMBER(1);
BEGIN 
	SELECT DISTINCT COUNT(o.order_id) INTO result 
	FROM tbl_orders o
	WHERE o.order_id = p_order_id;
	
	RETURN result;
END; 


/* TRIGGER Ask teacher about variable thingy */
CREATE OR REPLACE TRIGGER checkPayments
BEFORE INSERT ON tbl_payments
FOR EACH ROW 
DECLARE 
	v_message VARCHAR(32 CHAR);
        v_is_valid CHAR(1) := 'N';
BEGIN 
	
	IF getActiveUser(getOrderUsername(:new.order_id)) = 0 
	THEN v_message := 'Invalid account';

	ELSIF isValidAmount(:new.payment_amount) = 0
	THEN v_message := 'Invalid amount';

	ELSIF checkOrderExist(:new.order_id) = 0 
	THEN v_message := 'Invalid order ID';

	ELSE v_message := 'OK' ; 
        v_is_valid := 'Y';
	
	END IF;

	:new.payment_id:= seq_payment_id.nextval;
	:new.payment_date:= LOCALTIMESTAMP;
	:new.payment_message := v_message;
        :new.is_valid := v_is_valid;
END; 
/



/* Q21 + Inputted Data FROM XML */

/* 22 */
SELECT *
FROM tbl_payments;

/* 23 Output obtained correctly*/
DELETE
FROM tbl_payments;

/* 24 */
CREATE OR REPLACE FUNCTION getValidOrderPayments
(p_order_id IN tbl_orders.order_id%TYPE)
RETURN NUMBER 
	IS total NUMBER(10,2);
BEGIN 
	SELECT SUM(p.payment_amount) INTO total
	FROM tbl_payments p
	WHERE p.order_id = p_order_id AND p.is_valid = 'Y';
	
	RETURN total;

END; 

/* 25 */
SELECT o.order_id AS "Order ID",
getOrderTotal(o.order_id) AS "Order total",
getValidOrderPayments(o.order_id) AS "Valid payments total"
FROM tbl_orders o;

/* 26 */
/* Revised Trigger */
CREATE OR REPLACE TRIGGER checkPayments
BEFORE INSERT ON tbl_payments
FOR EACH ROW 
DECLARE 
	v_message VARCHAR(32 CHAR);
        v_is_valid CHAR(1) := 'N';
BEGIN 
	
	IF getActiveUser(getOrderUsername(:new.order_id)) = 0 
	THEN v_message := 'Invalid account';

	ELSIF isValidAmount(:new.payment_amount) = 0
	THEN v_message := 'Invalid amount';

	ELSIF checkOrderExist(:new.order_id) = 0 
	THEN v_message := 'Invalid order ID';
        
	ELSIF (getValidOrderPayments(:new.order_id) + :new.payment_amount ) > getOrderTotal(:new.order_id)
	THEN  v_message := 'Payment exceeds total';

	ELSE v_message := 'OK' ; 
        v_is_valid := 'Y';
	
	END IF;

	:new.payment_id:= seq_payment_id.nextval;
	:new.payment_date:= LOCALTIMESTAMP;
	:new.payment_message := v_message;
        :new.is_valid := v_is_valid;
	
END;

/* Clear payments */
DELETE
FROM tbl_payments;

/* Re uploaded the data + msg set */
SELECT * 
FROM tbl_payments;

/* Re run */ 
SELECT o.order_id AS "Order ID",
getOrderTotal(o.order_id) AS "Order total",
getValidOrderPayments(o.order_id) AS "Valid payments total"
FROM tbl_orders o;

/* 27 */
CREATE OR REPLACE PROCEDURE log_payment
	(p_payment_id IN tbl_payment_log.payment_id%TYPE,
	p_order_id IN tbl_payment_log.order_id%TYPE,
	p_order_total IN tbl_payment_log.order_total%TYPE,  
	p_paid_to_date IN tbl_payment_log.paid_to_date%TYPE,
	p_payment_amount IN tbl_payment_log.payment_amount%TYPE,  
	p_payment_date IN tbl_payment_log.payment_date%TYPE,
	p_is_valid IN tbl_payment_log.is_valid%TYPE,  
	p_payment_message IN tbl_payment_log.payment_message%TYPE)    
IS  
BEGIN  
	INSERT INTO tbl_payment_log(payment_id,order_id,order_total,paid_to_date,payment_amount,payment_date,is_valid,payment_message)  
	VALUES (p_payment_id,p_order_id,p_order_total,p_paid_to_date,p_payment_amount,p_payment_date,p_is_valid,p_payment_message);  
END; 

/* TRIGGER */
CREATE OR REPLACE TRIGGER checkPayments
BEFORE INSERT ON tbl_payments
FOR EACH ROW 
DECLARE 
	v_message VARCHAR(32 CHAR);
        v_is_valid CHAR(1) := 'N';
        v_timestamp TIMESTAMP := LOCALTIMESTAMP;
        v_payment_id INTEGER := seq_payment_id.nextval;
BEGIN 
	
	IF getActiveUser(getOrderUsername(:new.order_id)) = 0 
	THEN v_message := 'Invalid account';

	ELSIF isValidAmount(:new.payment_amount) = 0
	THEN v_message := 'Invalid amount';

	ELSIF checkOrderExist(:new.order_id) = 0 
	THEN v_message := 'Invalid order ID';
        
	ELSIF (getValidOrderPayments(:new.order_id) + :new.payment_amount ) > getOrderTotal(:new.order_id)
	THEN  v_message := 'Payment exceeds total';

	ELSE v_message := 'OK' ; 
        v_is_valid := 'Y';
	END IF;
       
	:new.payment_id:= v_payment_id;
	:new.payment_date:= v_timestamp;
	:new.payment_message := v_message;
        :new.is_valid := v_is_valid;
	
BEGIN
IF v_message = 'OK'
THEN
        log_payment
	(v_payment_id,
	:new.order_id,
	getOrderTotal(:new.order_id),  
	NVL((getValidOrderPayments(:new.order_id)),0) + :new.payment_amount , 
	:new.payment_amount,  
	v_timestamp,
	v_is_valid,  
	v_message);
ELSE 
 log_payment
	(v_payment_id,
	:new.order_id,
	getOrderTotal(:new.order_id),  
	NVL((getValidOrderPayments(:new.order_id)),0) , 
	:new.payment_amount,  
	v_timestamp,
	v_is_valid,  
	v_message);
END IF;
END;

END;
/

/* 28 */
CREATE OR REPLACE PROCEDURE paidInFull
(p_paid_to_date IN tbl_payment_log.paid_to_date%TYPE,
p_order_id IN tbl_payment_log.order_id%TYPE)
IS  
BEGIN
IF p_paid_to_date = getOrderTotal(p_order_id)
THEN
	UPDATE tbl_orders
        SET status_id = 3
        WHERE order_id = p_order_id;
END IF;
END;

/* Revised Trigger */
CREATE OR REPLACE TRIGGER checkPayments
BEFORE INSERT ON tbl_payments
FOR EACH ROW 
DECLARE 
	v_message VARCHAR(32 CHAR);
        v_is_valid CHAR(1) := 'N';
        v_timestamp TIMESTAMP := LOCALTIMESTAMP;
        v_payment_id INTEGER := seq_payment_id.nextval;
BEGIN 
	
	IF getActiveUser(getOrderUsername(:new.order_id)) = 0 
	THEN v_message := 'Invalid account';

	ELSIF isValidAmount(:new.payment_amount) = 0
	THEN v_message := 'Invalid amount';

	ELSIF checkOrderExist(:new.order_id) = 0 
	THEN v_message := 'Invalid order ID';
        
	ELSIF (getValidOrderPayments(:new.order_id) + :new.payment_amount ) > getOrderTotal(:new.order_id)
	THEN  v_message := 'Payment exceeds total';

	ELSE v_message := 'OK' ; 
        v_is_valid := 'Y';
	paidInFull((getValidOrderPayments(:new.order_id) + :new.payment_amount ),:new.order_id);
	END IF;
       
	:new.payment_id:= v_payment_id;
	:new.payment_date:= v_timestamp;
	:new.payment_message := v_message;
        :new.is_valid := v_is_valid;
BEGIN
IF v_message = 'OK'
THEN
     log_payment
	(v_payment_id,
	:new.order_id,
	getOrderTotal(:new.order_id),  
	NVL((getValidOrderPayments(:new.order_id)),0) + :new.payment_amount , 
	:new.payment_amount,  
	v_timestamp,
	v_is_valid,  
	v_message);
ELSE 
 log_payment
	(v_payment_id,
	:new.order_id,
	getOrderTotal(:new.order_id),  
	NVL((getValidOrderPayments(:new.order_id)),0) , 
	:new.payment_amount,  
	v_timestamp,
	v_is_valid,  
	v_message);
END IF;
END;

END;

/* Q29 Exported XML */

/* Q30 */

DROP SEQUENCE seq_payment_id; 

DROP TRIGGER checkPayments; 

DROP PROCEDURE log_payment;

DROP PROCEDURE paidInFull;

DROP FUNCTION isValidAmount;

DROP FUNCTION getActiveUser;

DROP FUNCTION getOrderTotal;

DROP FUNCTION getOrderUsername;

DROP FUNCTION checkOrderExist;

DROP FUNCTION getValidOrderPayments;


