/*
    The below code when ran will create an hotel lodging database with interesting features 
	FEATURES:
	1.) This database makes use of SQLSERVER AGENT
	2.) It also makes use of computed columms
*/

--HOTEL LODGING DATABASE

CREATE DATABASE HotelLodging
on PRIMARY(
    name = 'HotelLoding',
	FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\HotelLodging.mdf',
	size = 4mb,
	maxsize = 10mb,
	FILEGROWTH = 1mb
)
Log on(
     name = 'HotelLodgingLOG.ldf',
	 Filename = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\HotelLodgingLOG.ldf',
	 size = 1mb,
	 maxsize = 8mb,
	 FILEGROWTH = 1mb
  )


---------TABLES AND FU8NCTIONS IN THE HOTEL DATABASE
--ENSURE THAT YOU RUN ALL ACCORDINGLY
CREATE TABLE Clients(
   ID int identity(1,1) constraint clientsPK primary key,
   FirstName varchar(20) not null,
   LastName varchar(20) not null,
   PhoneNumber varchar(15) not null,
   EmailAddress varchar(50)
)

Create Table RoomStructure(
   StructureID TinyInt identity(1,1) constraint structurePK primary key,
   RoomType Varchar(20) not null constraint roomTypes check(RoomType in ('Single', 'Double', 'Mega', 'Enterprise')),
   DayPrice money not null constraint priceGreaterThanZero check(DayPrice > 0),
   Length tinyint not null,
   Breadth tinyint not null,
   NumberOfOccupants tinyint not null,
   NumberOfBeds tinyint not null,
   BedType varchar(20) not null,
   NumberOfFans tinyint not null,
   NumberOfTelevisions tinyint,
   NumberOfAC tinyint,
   NumberOfChairs tinyint,
   NumberOfTables tinyint
)

go
CREATE FUNCTION ChkIFBooked(@RoomID smallint)---Generates a room's availability status by checking if it has been booked
Returns Varchar(20)
as
Begin
   Declare @exitDate datetime, @entryDate datetime, @status varchar(20), @RoomsID smallint
   Select @exitDate = ExitDate, @entryDate = EntryDate from Bookings
   where Exists( Select Top 1 Room_Id from Bookings Where Room_ID = @RoomID order by EntryDate desc)
   
   if @entryDate is not null 
   begin
        if getdate() > @exitDate
        begin
	       set @status = 'Available'
	    end
        
		else if getdate() <  @exitDate
        begin
            if Getdate() < @entryDate
			begin
               set @status = 'Available'
			end
			Else
		       begin
		         set @status = 'Booked'
		       end
		end
   End
   
   Else
   Begin
      set @status = 'Available'
   End
End
   
go
Create TABLE Rooms(
   ID smallint IDENTITY(001,1) constraint RoomPK primary key,
   StructureID tinyint not null constraint strutFK foreign key(StructureID) references RoomStructure(StructureID) ON UPDATE CASCADE ON DELETE NO ACTION,
   AvailabilityStatus as dbo.CHKifBooked(ID),
   FloorLocation Varchar(20) not null check(FloorLocation in('First-Floor', 'Last-Floor'))
)

go
---Funtion to generate the day price of a room
Create Function getDayPrice(@Room_ID smallint)
returns smallmoney
as
begin
  Declare @DayPrice smallmoney
  Select @DayPrice = dayPrice from RoomStructure where StructureID = (Select StructureID from Rooms where ID = @Room_ID)
  return @DayPrice
end
go

------------Function to determine a booking status
go
Create Function getBookingStatus(@Booking_ID int)
returns Varchar(20)
as
   Begin
       Declare @status varchar(20), @entryDate datetime, @exitDate datetime
	   Select @entryDate = EntryDate, @exitDate = ExitDate from Bookings
       If @entryDate is not null 
	   begin
	        If getdate() < @EntryDate
	        Begin
	           set @status = 'Pending'
	        End
	        Else if getdate() between @entryDate and @exitDate
	        Begin
	           set @status = 'In-course'
	        End
	        Else if getdate() > @exitDate
	        Begin
	           set @status = 'Done'
	        End
		end
	Else
	begin
	    set @status ='Cancelled'
	end
	   return @status
	End

go



CREATE TABLE Bookings(
   ID int identity(100,3)primary key,
   Room_ID smallint not null foreign key (Room_ID) references Rooms(ID) on update Cascade on delete no action,
   Client_ID int not null Constraint Default_Value default 'Deleted' Constraint Client_ID foreign Key (Client_ID) references CLients(ID) on update Cascade on delete set default,
   BookingPlacementDate datetime default getdate(),
   BookingStatus as dbo.getBookingStatus(id),
   EntryDate datetime,
   ExitDate datetime,
   Constraint datebookedCHK check (EntryDate < ExitDate),
   BookingTotalCost as (dbo.getDayPrice(Room_ID) * (datediff(dd, EntryDate, ExitDate)))
)
go


-------Function to get a booking's total cost
CREATE FUNCTION GetBookingCost(@BookingID int)
returns smallmoney
as 
begin
    declare @TotalCost smallmoney
    Select @TotalCost = BookingTotalCost from Bookings
	where ID = @BookingID
    return @TotalCost
end


CREATE TABLE BookingPayment(
   ConfirmationID int identity(100, 1) primary key,
   BookingID int not null constraint bookingFK foreign key references Bookings(ID) ON UPDATE NO ACTION ON DELETE NO ACTION,
   ClientID int constraint ClientFK foreign key references Clients(ID) ON UPDATE CASCADE ON DELETE SET NULL,
   AmountPaid money constraint amountPaidCHK check(AmountPaid > 0),
   Deficit as dbo.GetBookingCost(BookingID) - AmountPaid,
   DateOfPayment datetime default getdate()
)

go

Create Table CancelledBookings(
    BookingID int constraint book_fk foreign key(BookingID) references Bookings(ID),
	Constraint bookPK primary key(BookingID),
	Initiator varchar(15) constraint chk_initiator check(initiator in ('Clients', 'Management')),
	Reason varchar(20) default 'Unpaid',
    CancelDate datetime default getdate()
)

-----------------------STORED PROCEDURES
------	This will be executed by a job,to cancel due bookings that are unpaid
Create Procedure cancelUnpaidBookings
as
Begin
      Declare @unpaidBooking table(Booking_ID int, EntryDate datetime, ExitDate datetime) 
      
      Insert into @unpaidBooking(Booking_ID, EntryDate, ExitDate)
      Select ID, EntryDate, ExitDate from Bookings
      where not Exists(Select BookingID from BookingPayment)

      ----------Evaluating if the various Bookings have been paid for before due date
      ---Else, the bookings will be cancelled
      
      --The below code will fish out those bookings that have not been paid for
      Update bookings
      set EntryDate = Null
      where ID in (Select Booking_ID from @unpaidBooking
			   where datediff(YYYY, getdate(), entryDate) <= 0 and 
			   datediff(MM, getdate(), entryDate) <= 0 and 
			   datediff(dd, getdate(), entryDate) <= 0
             )			                 
			 
      Update bookings
      set ExitDate = Null
      where ID in (Select Booking_ID from @unpaidBooking 
			   where datediff(YYYY, getdate(), entryDate) <= 0 and 
			   datediff(MM, getdate(), entryDate) <= 0 and 
			   datediff(dd, getdate(), entryDate) <= 0
             )

End


------Triggers
---This will automatically insert into cancelled bookings table
Create Trigger trig_CancelledBookings
on Bookings
after update
as 
Begin
      Declare @BookingID int, @entryDate date
	  Select @BookingID = Id, @entryDate = entryDate
	  from inserted

	  if @entryDate is null
	  begin
	       insert into CancelledBookings
		   values(@BookingID, 'Management', default, default)
	  end
	  
end


---------------------------------------------------Jobs
Exec dbo.sp_add_job 
     @job_name = 'Cancel_Unpaid_Bookings',
	 @description = 'This job will query all bookings, and delete any that is due and has not been paid for'

Exec dbo.sp_add_jobStep
     @Job_name = 'Cancel_Unpaid_Bookings',
	 @step_name = 'Run_cancel_unpaid_bookings',
	 @database_name = N'HotelLodging',
	 @subsystem = N'TSQL',
	 @command = N'Exec cancelUnpaidBookings',
	 @retry_attempts = 2,
	 @retry_interval = 1

Exec dbo.sp_add_jobschedule
     @Job_name = 'Cancel_Unpaid_Bookings' ,
	 @name = 'DailySchedule',
	 @enabled = 1,
	 @freq_type = 4,
	 @freq_interval = 1,
	 @active_start_date = 20240128,-----PLEASE UPDATE TO YOUR CURRENT DATE 
	 @active_start_time = 103000

