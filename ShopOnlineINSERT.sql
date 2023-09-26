/*
        Inserting Data into ShopOnline Database
---This code would insert data from the adventure works database to ShopOnline Database
*/


-----Inserting first 290 customer details
Create table #Customers(
   First_Name varchar(20), 
   Middle_Name varchar(20), 
   Last_Name varchar(20), 
   Gender Char(2), 
   Date_Of_Birth Datetime, 
   Phone Varchar(30), 
   Email varchar(40)
)
use AdventureWorks
Insert into #Customers
go
Select FirstName, MiddleName, LastName, Gender, BirthDate, Phone, EmailAddress
from Person.Contact as cont
join HumanResources.Employee as emp
on cont.ContactID = emp.ContactID

use ShopOnline
Insert into Customers(First_Name, Middle_Name, Last_Name, Gender, Date_Of_Birth, Phone_Number, Email_Address)
Select * from humanresources.employee



-----------Inserting next 1 customer details, making a total of 500 records
drop table #Customers
--Re-create #customers table
--Inserting customized records into #Customers Table
use AdventureWorks
Insert into #Customers
Select LastName, MiddleName, FirstName, Gender ,dateAdd(yyyy, 1, BirthDate), Phone, concat(1,EmailAddress)
from Person.Contact as conT
join HumanResources.Employee as emp
on cont.ContactID = emp.ContactID

use ShopOnline
Insert into Customers(First_Name, Middle_Name, Last_Name, Gender, Date_Of_Birth, Phone_Number, Email_Address)
Select top 1 * from #Customers




-----------------Inserting into CustomerAddress Table
Create table #Cust_Address(
  EmployeeID smallint identity(1,1),
  Street varchar(60),
  City varchar(60),
  State varchar(50),
  Country varchar(60)
)
go
--Retreiving data from AdventureWorks DataBase
use AdventureWorks
insert into #Cust_Address(Street, City, State, Country)
Select top 300 AddressLine1, City, Sta.Name, cont.Name
from Person.Address as addr
Join Person.StateProvince as Sta
on addr.StateProvinceID = Sta.StateProvinceID
join Person.CountryRegion as cont
on sta.countryRegionCode = cont.CountryRegionCode


Use ShopOnline
Insert into Customer_Address
select * from #Cust_Address

Select * from Customer_Address




---------------Inserting into products Table
Create Table #Product_Name(
  id smallint identity(1,1),
  Name varchar(50)
)

Create Table #Product_details(
  Name varchar(50),
  UnitPrice money,
  Quantity smallint identity(100, 1)
)

Create Table #Product_Price(
   Id smallint identity(1, 1),
   nullID smallint,
   Price smallmoney,
)

use AdventureWorks
insert into #Product_Name
select top 50 Name from Production.Product

insert into #Product_Price
Select top 50 Count(ProductID), UnitPrice from Sales.SalesOrderDetail
Group by ProductID, UnitPrice

Insert into #Product_details(Name, UnitPrice)
Select prod.Name, price from #Product_Name as prod
join #Product_Price as price
on prod.id = price.Id


--Products details
Use ShopOnline
insert into Products
Select * from #Product_details

Select * from Products


----------Inserting into Orders
/*
  ProductQuantity
  PaymentMeans
  OrderDate
  DeliveryDate
  TotalCost
*/
drop table #Product_Demo
Create table #Product_Demo(
  CustomerID smallint,
  ProductID smallint identity(2,1),
  ProductQuantity smallint default 2,
  OrderDate datetime default dateadd(week, -1, getdate()),
  Delivery_Date datetime default dateadd(week, 2,getdate())
)
go
 
Select * from Products
Select * from #Product_Demo

set identity_insert #Product_Demo on
Delete from #Product_Demo

insert into #Product_Demo(CustomerID)
Select Customer_ID from Customers
where Customer_ID between 200 and 249

Update #Product_Demo
set ProductQuantity = 3
where CustomerID between 100 and 130




--------------Inserting into Orders
Insert into Orders(Customer_ID, Product_ID, Product_Quantity, Order_Date, Delivery_Date)
Select * from #Product_Demo

select * into OrdersA
From Orders

Select * from Purchases
Select * from Products
---------------Inserting into Purchases
Insert into Purchases(Product_ID, Quantity_Purchased)
Select Product_ID, Product_Quantity from Orders