create database flipkart_project;
use flipkart_project;
show tables;
describe orders_table;
describe routes_table;
describe warehouse_table;
describe deliveryagents_table;
describe shipmenttracking_table;
select*from orders_table;

ALTER TABLE orders_table
MODIFY Order_ID VARCHAR(20),
MODIFY Warehouse_ID VARCHAR(10),
MODIFY Route_ID VARCHAR(10),
MODIFY Agent_ID VARCHAR(10),
MODIFY Order_Date DATE,
MODIFY Expected_Delivery_Date DATE,
MODIFY Actual_Delivery_Date DATE,
MODIFY Status VARCHAR(50),
MODIFY Order_Value DECIMAL(10,2);

describe orders_table;

select*from orders_table;
SELECT Order_ID, COUNT(*) AS cnt
FROM orders_table
GROUP BY Order_ID
HAVING COUNT(*) > 1;

SELECT *FROM orders_table
WHERE Actual_Delivery_Date < Order_Date;

select *from orders_table;

SELECT Order_ID,Expected_Delivery_Date,Actual_Delivery_Date,
DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) AS Delay_Days
FROM orders_table;

SELECT  Order_ID,
DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) AS Delay_Days
FROM orders_table
ORDER BY Delay_Days DESC
LIMIT 10;

SELECT Route_ID,AVG(DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date)) AS Avg_Delay_Days FROM orders_table GROUP BY Route_ID
ORDER BY Avg_Delay_Days DESC LIMIT 10;


SELECT Warehouse_ID,Order_ID,DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) AS Delay_Days,RANK() OVER(PARTITION BY Warehouse_ID 
ORDER BY DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) DESC) AS Rank_in_Warehouse FROM orders_table;


SELECT Route_ID, ROUND(AVG(DATEDIFF(Actual_Delivery_Date, Order_Date)),2) AS Avg_Delivery_Time FROM orders_table GROUP BY Route_ID;

select *from orders_table;

SELECT Route_ID,AVG(Traffic_Delay_Min) AS Avg_Traffic_Delay FROM routes_table GROUP BY route_id;
SELECT r.Route_ID,r.Distance_KM,r.Average_Travel_Time_Min,ROUND(r.Distance_KM / r.Average_Travel_Time_Min, 2) AS Efficiency_Ratio FROM routes_table r;
SELECT Route_ID,Start_Location,End_Location,Distance_KM,Average_Travel_Time_Min,Traffic_Delay_Min,ROUND(Distance_KM / Average_Travel_Time_Min, 2) 
AS Efficiency_Ratio FROM routes_table ORDER BY Efficiency_Ratio ASC LIMIT 3;

SELECT Route_ID, COUNT(*) AS Total_Orders, SUM(CASE WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 ELSE 0 END) AS Delayed_Orders,    
ROUND(SUM(CASE WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 ELSE 0 END) * 100.0 / COUNT(*),   2) AS Delay_Percentage
FROM orders_table GROUP BY Route_ID HAVING SUM(CASE WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 20 
ORDER BY Delay_Percentage DESC;

SELECT Warehouse_ID, Warehouse_Name, City, Average_Processing_Time_Min FROM warehouse_table ORDER BY Average_Processing_Time_Min DESC LIMIT 3;

SELECT Warehouse_ID,COUNT(*) AS Total_Orders,SUM(CASE WHEN Actual_Delivery_Date > Expected_Delivery_Date THEN 1 ELSE 0 END) AS Delayed_Orders 
FROM orders_table GROUP BY Warehouse_ID;

WITH avg_time AS (SELECT AVG(DATEDIFF(Actual_Delivery_Date, Order_Date)) AS Global_Avg    
FROM orders_table)SELECT o.Warehouse_ID,AVG(DATEDIFF(o.Actual_Delivery_Date, o.Order_Date)) AS Avg_Time 
FROM orders_table o CROSS JOIN avg_time a GROUP BY o.Warehouse_ID HAVING AVG(DATEDIFF(o.Actual_Delivery_Date, o.Order_Date)) > (SELECT Global_Avg FROM avg_time) 
ORDER BY Avg_Time DESC;

SELECT Warehouse_ID,ROUND(SUM(CASE WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS On_Time_Percentage,
RANK() OVER (ORDER BY SUM(CASE WHEN Actual_Delivery_Date <= Expected_Delivery_Date THEN 1 ELSE 0 END) * 1.0 / COUNT(*) DESC) AS Rank_Position 
FROM orders_table GROUP BY Warehouse_ID;

SELECT Agent_ID,Agent_Name,Route_ID,Avg_Speed_KMPH,On_Time_Delivery_Percentage,Experience_Years,RANK() OVER (PARTITION BY Route_ID ORDER BY On_Time_Delivery_Percentage DESC)
AS Rank_In_Route FROM deliveryagents_table ORDER BY Route_ID, Rank_In_Route;

SELECT Agent_ID, Agent_Name,Route_ID, Avg_Speed_KMPH, On_Time_Delivery_Percentage,Experience_Years, CASE        
WHEN On_Time_Delivery_Percentage < 73 THEN 'Critical – Below 73%'        
WHEN On_Time_Delivery_Percentage < 77 THEN 'Poor – 73% to 77%'        
ELSE 'Below Average – 77% to 80%'    
END AS Performance_Level FROM deliveryagents_table WHERE On_Time_Delivery_Percentage < 80 ORDER BY On_Time_Delivery_Percentage ASC;


SELECT 'Top 5 Agents (Best On-Time %)' AS Agent_Group, ROUND(AVG(Avg_Speed_KMPH), 2) AS Avg_Speed_KMPH 
FROM (SELECT Avg_Speed_KMPH FROM deliveryagents_table ORDER BY On_Time_Delivery_Percentage DESC LIMIT 5) top5 
UNION ALL SELECT 'Bottom 5 Agents (Worst On-Time %)'  AS Agent_Group, 
ROUND(AVG(Avg_Speed_KMPH), 2) AS Avg_Speed_KMPH FROM (SELECT Avg_Speed_KMPH FROM deliveryagents_table ORDER BY On_Time_Delivery_Percentage ASC LIMIT 5) bottom5;

WITH RankedCheckpoints AS (SELECT Order_ID,Checkpoint,Checkpoint_Time,Delay_Reason,Delay_Minutes,ROW_NUMBER() 
OVER (PARTITION BY Order_ID ORDER BY Checkpoint_Time DESC ) AS rn FROM shipmenttracking_table) 
SELECT  Order_ID, Checkpoint  AS Last_Checkpoint, Checkpoint_Time AS Last_Checkpoint_Time,Delay_Reason,Delay_Minutes 
FROM RankedCheckpoints WHERE rn = 1 ORDER BY Order_ID;

SELECT Delay_Reason, COUNT(*) AS Occurrences,  SUM(Delay_Minutes) AS Total_Delay_Minutes, ROUND(AVG(Delay_Minutes), 2) AS Avg_Delay_Per_Incident,
RANK() OVER (ORDER BY COUNT(*) DESC) AS Frequency_Rank FROM shipmenttracking_table WHERE Delay_Reason IS NOT NULL AND 
UPPER(TRIM(Delay_Reason)) != 'NONE' GROUP BY Delay_Reason ORDER BY Occurrences DESC;

SELECT Order_ID,COUNT(*) AS Total_Checkpoints, SUM(CASE WHEN Delay_Minutes > 0 THEN 1 ELSE 0 END) AS Delayed_Checkpoints,
SUM(Delay_Minutes) AS Total_Delay_Minutes FROM shipmenttracking_table GROUP BY Order_ID HAVING 
SUM(CASE WHEN Delay_Minutes > 0 THEN 1 ELSE 0 END) > 2 ORDER BY Delayed_Checkpoints DESC;

SELECT r.Start_Location AS Region,COUNT(o.Order_ID) AS Total_Orders,ROUND(AVG(DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date)),2)  AS Avg_Delay_Days,
SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date,o.Expected_Delivery_Date) > 0 THEN 1 ELSE 0 END) AS Delayed_Orders,ROUND(100.0 * 
SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date,o.Expected_Delivery_Date) <= 0 THEN 1 ELSE 0 END) /
COUNT(o.Order_ID), 2) AS OnTime_Pct FROM orders_table o JOIN routes_table r ON 
o.Route_ID = r.Route_ID GROUP BY r.Start_Location ORDER BY Avg_Delay_Days DESC;


SELECT COUNT(*) AS Total_Deliveries,SUM(CASE WHEN DATEDIFF(Actual_Delivery_Date,Expected_Delivery_Date) <= 0 THEN 1 ELSE 0 END) AS OnTime_Deliveries,
SUM(CASE WHEN DATEDIFF(Actual_Delivery_Date,Expected_Delivery_Date) > 0  THEN 1 ELSE 0 END) AS Delayed_Deliveries,
ROUND(100.0 * SUM(CASE WHEN DATEDIFF(Actual_Delivery_Date,Expected_Delivery_Date) <= 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS OnTime_Delivery_Pct FROM orders_table;

SELECT Route_ID, Start_Location, End_Location, Traffic_Delay_Min AS Avg_Traffic_Delay_Min, 
RANK() OVER (ORDER BY Traffic_Delay_Min DESC) AS Delay_Rank, CASE WHEN Traffic_Delay_Min >= 80 THEN 'High Traffic Impact' 
WHEN Traffic_Delay_Min >= 50 THEN 'Medium Traffic Impact' ELSE 'Low Traffic Impact' END AS Traffic_Category FROM routes_table 
ORDER BY Traffic_Delay_Min DESC;



























    
   















