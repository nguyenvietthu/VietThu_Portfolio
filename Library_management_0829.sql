USE DB_LibraryManagement;
GO
-- Xem các bảng trong DB
SELECT * FROM tbl_book;

SELECT * FROM tbl_book_authors;

SELECT * FROM tbl_book_copies;

SELECT * FROM tbl_book_loans;

SELECT * FROM tbl_borrower;

SELECT * FROM tbl_library_branch;

SELECT * FROM tbl_publisher;

/* #1- How many copies of the book titled "The Lost Tribe" are owned by the library branch whose name is "Sharpstown"? */
-- Viet Thu
CREATE PROCEDURE bookCopiesAtAllSharpstown1
(@bookTitle varchar(70) = 'The Lost Tribe', @branchName varchar(70) = 'Sharpstown')
AS
SELECT copies.book_copies_BranchID as [Branch ID], book.book_Title as [Title Book], branch.library_branch_BranchName as [Branch Name],
       copies.book_copies_No_Of_Copies as [Num] 
	   FROM tbl_book_copies as copies 
			INNER JOIN tbl_book as book ON copies.book_copies_BookID = book.book_BookID
			INNER JOIN tbl_library_branch as branch ON copies.book_copies_BranchID = branch.library_branch_BranchID
	   WHERE book.book_Title = @bookTitle AND branch.library_branch_BranchName =@branchName;
GO
EXEC bookCopiesAtAllSharpstown1 @booktitle = 'It';
/* #2- How many copies of the book titled "The Lost Tribe" are owned by each library branch? */
-- Viet Thu
CREATE PROCEDURE CopiesBookAtAllBranches1
(@bookTitle varchar(70) = 'The Lost Tribe')
AS
SELECT copies.book_copies_BranchID as [Branch ID],
	   branch.library_branch_BranchName as [Branch Name],
	   copies.book_copies_No_Of_Copies as [Soluong],
	   book.book_title as [Book Title]
  FROM dbo.tbl_book_copies as copies 
       INNER JOIN dbo.tbl_library_branch as branch ON copies.book_copies_BranchID = branch.library_branch_BranchID
	   INNER JOIN dbo.tbl_book as book ON book.book_BookID = copies.book_copies_BookID
	   WHERE book.book_Title = @bookTitle
GO
EXEC CopiesBookAtAllBranches1 @bookTitle = 'It';

/* #3- Retrieve the names of all borrowers who do not have any books checked out. */
SELECT *
FROM dbo.tbl_borrower as borrower
WHERE NOT EXISTS ( SELECT loan.book_loans_CardNo
					FROM dbo.tbl_book_loans as loan
					WHERE loan.book_loans_CardNo = borrower.borrower_CardNo
				)
-- Kiểm chứng kết quả
SELECT *
FROM dbo.tbl_borrower as borrower
LEFT JOIN dbo.tbl_book_loans as loans
       ON borrower.borrower_CardNo = loans.book_loans_CardNo;
/* #4- For each book that is loaned out from the "Sharpstown" branch and whose DueDate is today, retrieve the book title, the borrower's name, and the borrower's address.  */
CREATE PROCEDURE LoanersINFO
(@DueDate date = NULL, @BranchName varchar(50) = 'Sharpstown' )
AS
SET @DueDate = GETDATE()
SELECT book.book_Title as [Book Title], borrower.borrower_BorrowerName as [Borrower Name],
	   borrower.borrower_BorrowerAddress as [BorrowerAddress]
  FROM dbo.tbl_book_loans as loans 
	   INNER JOIN dbo.tbl_borrower as borrower ON loans.book_loans_CardNo = borrower.borrower_CardNo
	   INNER JOIN dbo.tbl_book as book ON  book.book_BookID = loans.book_loans_BookID
       INNER JOIN dbo.tbl_library_branch as branch ON loans.book_loans_BranchID = branch.library_branch_BranchID 
 WHERE branch.library_branch_BranchName = @BranchName AND loans.book_loans_DueDate = @DueDate;
 GO
 EXEC LoanersINFO;
/* #5- For each library branch, retrieve the branch name and the total number of books loaned out from that branch.  */
CREATE PROCEDURE TotalloanBOOKperBranch
AS
SELECT branch.library_branch_BranchName as [Branch Name],
	   COUNT(loans.book_loans_BookID) as [NUM_book_loan]
  FROM dbo.tbl_book_loans as loans 
       INNER JOIN dbo.tbl_library_branch as branch ON branch.library_branch_BranchID = loans.book_loans_BranchID
 GROUP BY branch.library_branch_BranchName
GO

EXEC TotalloanBOOKperBranch;
-- Kiem chung ket qua
SELECT * 
FROM dbo.tbl_library_branch as branch
INNER JOIN dbo.tbl_book_loans as loans ON loans.book_loans_BranchID = branch.library_branch_BranchID
ORDER BY branch.library_branch_BranchName;
/* #6- Retrieve the names, addresses, and number of books checked out for all borrowers who have more than five books checked out. */
SELECT borrower.borrower_BorrowerName, borrower.borrower_BorrowerAddress, COUNT(loans.book_loans_BookID) as num_borrowed
FROM  dbo.tbl_book_loans as loans 
INNER JOIN dbo.tbl_borrower as borrower ON loans.book_loans_CardNo = borrower.borrower_CardNo
GROUP BY borrower.borrower_BorrowerName, borrower.borrower_BorrowerAddress
HAVING COUNT(loans.book_loans_BookID) >= 5 ;


/* #7- For each book authored by "Stephen King", retrieve the title and the number of copies owned by the library branch whose name is "Central".*/
SELECT author.book_authors_AuthorName as [AuthorName],
	   book.book_Title as [Book Title],
	   branch.library_branch_BranchName  as [BranchName],
	   SUM(copies.book_copies_No_Of_Copies) [Total Copies]
  FROM dbo.tbl_book_authors as author 
       INNER JOIN dbo.tbl_book as book ON author.book_authors_BookID = book.book_BookID
	   INNER JOIN dbo.tbl_book_copies as copies ON author.book_authors_BookID = copies.book_copies_BookID
	   INNER JOIN dbo.tbl_library_branch as branch ON branch.library_branch_BranchID = copies.book_copies_BranchID
	   WHERE branch.library_branch_BranchName = 'Central' AND author.book_authors_AuthorName = 'Stephen King'
	   GROUP BY author.book_authors_AuthorName, book.book_Title,branch.library_branch_BranchName ;


CREATE PROCEDURE dbo.BookbyAuthorandBranch
	(@BranchName varchar(50) = 'Central', @AuthorName varchar(50) = 'Stephen King')
AS
	SELECT Branch.library_branch_BranchName AS [Branch Name], Book.book_Title AS [Title], Copies.book_copies_No_Of_Copies AS [Number of Copies]
		   FROM tbl_book_authors AS Authors
				INNER JOIN tbl_book AS Book ON Authors.book_authors_BookID = Book.book_BookID
				INNER JOIN tbl_book_copies AS Copies ON Authors.book_authors_BookID = Copies.book_copies_BookID
				INNER JOIN tbl_library_branch AS Branch ON Copies.book_copies_BranchID = Branch.library_branch_BranchID
			WHERE Branch.library_branch_BranchName = @BranchName AND Authors.book_authors_AuthorName = @AuthorName
GO	
EXEC dbo.BookbyAuthorandBranch

/* ==================================== STORED PROCEDURE QUERY QUESTIONS =================================== */

	SELECT Branch.library_branch_BranchName AS [Branch Name], Book.book_Title AS [Title], Copies.book_copies_No_Of_Copies AS [Number of Copies]
		   FROM tbl_book_authors AS Authors
				INNER JOIN tbl_book AS Book ON Authors.book_authors_BookID = Book.book_BookID
				INNER JOIN tbl_book_copies AS Copies ON Authors.book_authors_BookID = Copies.book_copies_BookID
				INNER JOIN tbl_library_branch AS Branch ON Copies.book_copies_BranchID = Branch.library_branch_BranchID