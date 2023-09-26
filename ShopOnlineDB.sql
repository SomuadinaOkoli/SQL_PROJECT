Create Database ShopOnline
on Primary(
    Name = 'ShopOnline',
	FileName = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\ShopOnline.mdf',
	size = 5mb,
	maxsize = 20mb,
	FileGrowth = 2mb
)
log on(
    Name = 'ShopOnline_Log',
	FileName = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\ShopOnline_Log.ldf',
	size = 3mb,
	Maxsize = 8mb,
	FileGrowth = 1mb
)



Create Table Customers(
    Customer_ID smallint identity(1,1) constraint Customers_PK primary key,
	First_Name varchar(20) not null,
	Middle_Name varchar(20),
	Last_Name varchar(20) not null,
	Gender char(2) not null constraint Gender_CHK check(Gender in ('M', 'F')),
	Current_Age as DateDiff(yyyy, Date_Of_Birth, getdate()),
	Date_Of_Birth datetime not null,
	Phone_Number varchar(30) not null,
	Email_Address varchar(40) not null,
	Sign_Up_Date datetime constraint Sign_Up_Date_Def Default getdate() 

)

go
Create Table Customer_Address(
    Customer_ID smallint constraint Customer_FK foreign key(Customer_ID) references Customers(Customer_ID) on Update Cascade on Delete set null,
	Street_Address varchar(50) not null,
	City Varchar(30) not null,
	Sate Varchar(40) not null,
	Country Varchar(50) not null
)

Create Table Products(
   Product_ID SmallInt Identity(1,1) Constraint Product_PK primary key,
   Product_Name varchar(50) not null,
   Unit_Price money not null,
   Quantity  smallint not null
)
drop table Customers
Create Table Orders(
   Order_ID smallint identity(100,1) constraint Orders_PK primary key,
   Customer_ID smallint not null constraint CustomerT_FK foreign key(Customer_ID) references Customers(Customer_ID) on Update cascade on delete cascade,
   Product_ID smallint not null Constraint Products_FK foreign key(Product_ID) references Products(Product_ID) on Update cascade on Delete no action,
   Product_Quantity Smallint not null,
   Order_Cost as dbo.GetUnitPrice(Product_ID) * Product_Quantity,
   Payment_Means varchar(20) constraint Payment_means_Def default 'Transfer',
   Order_Date datetime constraint order_date_Def Default getDate(),
   Delivery_Date datetime,
   constraint DeliGreaterThanOrder check( Order_Date < Delivery_Date),
   Order_Status as dbo.CHK_Order_Status(Delivery_Date)
)
Alter Table Orders
Add Order_Status as dbo.CHK_Order_Status(Delivery_Date)

Alter Table Orders
Drop column Order_Status

Create Table Purchases(
   Transaction_ID smallint identity(100, 1) constraint Purchases_PK primary key,
   Product_ID smallint constraint Purchase_def default null constraint Product_FK foreign key(Product_ID) references Products(Product_ID) on Update cascade on delete set default,
   Quantity_Purchased smallint not null,
   Cost_Price as dbo.GetUnitPrice(Product_ID),
   Total_Cost as dbo.GetUnitPrice(Product_ID) * Quantity_Purchased
)

go
-------Function
Create function GetUnitPrice(@Product_ID smallint)
returns smallmoney
as
Begin
  Declare @unit_price smallmoney
  select @unit_price = Unit_Price from Products
  where Product_ID = @Product_ID

  return @unit_price
End
go
-------
Drop function CHK_Order_Status
go
Create function Chk_Order_Status(@Delivery_Date datetime)
returns varchar(20)
As
Begin
   Declare @Status varchar(20)
   Select @Status = Case 
                       when getDate() < Delivery_Date 
					        then 'Pending'
                       When Datepart(dd, getdate()) = Datepart(dd,Delivery_Date) and Datepart(mm, getdate()) = Datepart(mm,Delivery_Date) and Datepart(yyyy, getdate()) = Datepart(yyyy,Delivery_Date)
				            then 'In-Transit'
				       Else 'Delivered'
					end
	from Orders
	return @Status
end
----------------------Triggers
select getdate()
go
Create Trigger Update_Product_Qty
on Purchases
After insert
As
Begin
    Declare @Quantity smallint, @Product_ID smallint
    Select @Product_ID = Product_ID, @Quantity = Quantity_Purchased from inserted

	Update Products
	set Quantity = Quantity +  @Quantity
	where Product_ID = @Product_ID
end
go
Create Trigger Deduct_Product_Qty
on Orders
After insert
As
Begin
    Declare @Quantity smallint, @Product_ID smallint
    Select @Product_ID = Product_ID, @Quantity = Product_Quantity from inserted

	Update Products
	set Quantity = Quantity - @Quantity
	where Product_ID = @Product_ID
end