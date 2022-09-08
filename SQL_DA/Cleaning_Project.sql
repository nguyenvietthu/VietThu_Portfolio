/*

		CLEANING DATA WITH SQL			

*/
USE VT_PortfolioProject
GO

SELECT * FROM NashvilleHousing

-------------------------------------------------------------------------------------------------------------------------

-- Standard Date Format

SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM NashvilleHousing;

UPDATE dbo.NashvilleHousing
SET SaleDate = CONVERT(DATE, SaleDate); -- but Can't ??

ALTER TABLE dbo.NashvilleHousing 
ADD SaleDateConverted Date;

UPDATE dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate); -- Now I'm done 


-------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data
-- 1. First I check null and duplicate value
SELECT *
FROM NashvilleHousing
--WHERE PropertyAddress is NULL
ORDER BY ParcelID;

-- We have the each duplicate case of PropertyAddress has the same ParcelID, but not the same ID, We'll conduct the selfjoin to fill NULL value 
SELECT a.ParcelID, a.PropertyAddress,  b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing as a
JOIN NashvilleHousing as b
  ON a.ParcelID = b.ParcelID
  AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL ;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing as a
JOIN NashvilleHousing as b
  ON a.ParcelID = b.ParcelID
  AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL;



-------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into  Individual columns (Address, City, State)
-- PropertyAddress first
SELECT PropertyAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))
FROM dbo.NashvilleHousing;

ALTER TABLE dbo.NashvilleHousing 
ADD PropertySplitAddress NVARCHAR(255)
GO
UPDATE dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

ALTER TABLE dbo.NashvilleHousing 
ADD PropertySplitCity NVARCHAR(255)
GO
UPDATE dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

SELECT *
FROM dbo.NashvilleHousing;

-- Second, Owner Address

SELECT OwnerAddress,
PARSENAME(REPLACE(OwnerAddress,',','.'), 3), 
PARSENAME(REPLACE(OwnerAddress,',','.'), 2), 
PARSENAME(REPLACE(OwnerAddress,',','.'), 1)
FROM dbo.NashvilleHousing;

ALTER TABLE dbo.NashvilleHousing 
ADD OwnerSplitAddress NVARCHAR(255)
GO
UPDATE dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3);

ALTER TABLE dbo.NashvilleHousing 
ADD OwnerSplitCity NVARCHAR(255)
GO
UPDATE dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2);

ALTER TABLE dbo.NashvilleHousing 
ADD OwnerSplitState NVARCHAR(255)
GO
UPDATE dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1);

SELECT *
FROM dbo.NashvilleHousing;



-------------------------------------------------------------------------------------------------------------------------

-- Change Y/N to Yes/No in "SoldAsVacant" field;

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM dbo.NashvilleHousing
GROUP BY SoldAsVacant;


SELECT  SoldAsVacant, 
(
	CASE SoldAsVacant  
	WHEN 'Y' THEN 'Yes'
	WHEN 'N' THEN 'No'
	ELSE SoldAsVacant 
	END
) as SoldAsVacant_1
FROM dbo.NashvilleHousing;

UPDATE dbo.NashvilleHousing
SET SoldAsVacant = CASE SoldAsVacant  
	WHEN 'Y' THEN 'Yes'
	WHEN 'N' THEN 'No'
	ELSE SoldAsVacant 
	END;



-------------------------------------------------------------------------------------------------------------------------

-- Remove duplicate values;
WITH cte AS (
    SELECT *, 
        ROW_NUMBER() OVER (
            PARTITION BY 
                ParcelID,
				PropertyAddress,
				SaleDate,
				SalePrice,
				LegalReference
            ORDER BY 
                UniqueID
        ) row_num
     FROM 
        dbo.NashvilleHousing
)
--DELETE
SELECT *
FROM cte
WHERE row_num > 1;


-------------------------------------------------------------------------------------------------------------------------

SELECT * FROM dbo.NashvilleHousing;

-- Remove unused Columns
ALTER TABLE dbo.NashvilleHousing 
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress, TaxDistrict;
