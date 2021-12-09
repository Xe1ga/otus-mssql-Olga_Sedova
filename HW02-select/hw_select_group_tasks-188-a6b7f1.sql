/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT WideWorldImporters.Warehouse.StockItems.StockItemID, WideWorldImporters.Warehouse.StockItems.StockItemName
FROM WideWorldImporters.Warehouse.StockItems
WHERE WideWorldImporters.Warehouse.StockItems.StockItemName LIKE '%urgent%' OR WideWorldImporters.Warehouse.StockItems.StockItemName LIKE 'Animal%';

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT Suppliers.SupplierID, Suppliers.SupplierName
FROM WideWorldImporters.Purchasing.Suppliers AS Suppliers
LEFT JOIN WideWorldImporters.Purchasing.PurchaseOrders AS PurchaseOrders ON PurchaseOrders.SupplierID = Suppliers.SupplierID
WHERE PurchaseOrders.PurchaseOrderID IS NULL;

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT DISTINCT
Orders.OrderID AS OrderID,
FORMAT(Orders.OrderDate, 'dd.MM.yyyy') AS OrderDate,
DATENAME(month, Orders.OrderDate) AS MonthOrderDate,
DATEPART(quarter, Orders.OrderDate) AS QuarterOrderDate,
CEILING(CAST(DATEPART(month, Orders.OrderDate) AS float)/4) AS ThirdOfTheYearOrderDate,
Customers.CustomerName AS CustomerName
FROM WideWorldImporters.Sales.Orders AS Orders
JOIN WideWorldImporters.Sales.Customers AS Customers ON Customers.CustomerID = Orders.CustomerID
JOIN WideWorldImporters.Sales.OrderLines AS OrderLines ON OrderLines.OrderID = Orders.OrderID
WHERE (OrderLines.UnitPrice > 100 OR OrderLines.Quantity > 20) AND OrderLines.PickingCompletedWhen IS NOT NULL
ORDER BY QuarterOrderDate, ThirdOfTheYearOrderDate, OrderDate
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY;

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/
SELECT 
DeliveryMethods.DeliveryMethodName AS DeliveryMethodName,
PurchaseOrders.ExpectedDeliveryDate AS ExpectedDeliveryDate,
Suppliers.SupplierName AS SupplierName,
People.FullName As ContactPerson
FROM WideWorldImporters.Purchasing.PurchaseOrders AS PurchaseOrders 
JOIN WideWorldImporters.Application.DeliveryMethods AS DeliveryMethods ON DeliveryMethods.DeliveryMethodID = PurchaseOrders.DeliveryMethodID
JOIN WideWorldImporters.Purchasing.Suppliers AS Suppliers ON Suppliers.SupplierID = PurchaseOrders.SupplierID
JOIN WideWorldImporters.Application.People AS People ON People.PersonID = PurchaseOrders.ContactPersonID
WHERE (PurchaseOrders.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31')
AND DeliveryMethods.DeliveryMethodName IN ('Air Freight', 'Refrigerated Air Freight')
AND PurchaseOrders.IsOrderFinalized = 1


/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10 Orders.OrderDate, PeopleCustomer.FullName, PeopleSalesPerson.FullName
FROM WideWorldImporters.Sales.Orders AS Orders
JOIN WideWorldImporters.Application.People AS PeopleCustomer ON PeopleCustomer.PersonID = Orders.CustomerID
JOIN WideWorldImporters.Application.People AS PeopleSalesPerson ON PeopleSalesPerson.PersonID = Orders.SalespersonPersonID
ORDER BY Orders.OrderDate DESC
/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT DISTINCT People.PersonID, People.FullName, People.PhoneNumber
FROM WideWorldImporters.Application.People
JOIN WideWorldImporters.Sales.Orders AS Orders ON Orders.CustomerID = People.PersonID
JOIN WideWorldImporters.Sales.OrderLines AS OrderLines ON OrderLines.OrderID = Orders.OrderID
JOIN WideWorldImporters.Warehouse.StockItems AS StockItems ON StockItems.StockItemID = OrderLines.StockItemID
WHERE StockItems.StockItemName = 'Chocolate frogs 250g'


/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT YEAR(Invoices.InvoiceDate) AS YearInvoice, MONTH(Invoices.InvoiceDate) AS MonthInvoice, AVG(InvoiceLines.UnitPrice) AS AvgInvoice, SUM(InvoiceLines.ExtendedPrice) AS SumInvoice
FROM WideWorldImporters.Sales.Invoices AS Invoices
JOIN WideWorldImporters.Sales.InvoiceLines AS InvoiceLines ON InvoiceLines.InvoiceID = Invoices.InvoiceID
GROUP BY MONTH(Invoices.InvoiceDate), YEAR(Invoices.InvoiceDate)
ORDER BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate)

/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT YEAR(Invoices.InvoiceDate) AS YearInvoice, MONTH(Invoices.InvoiceDate) AS MonthInvoice, SUM(InvoiceLines.ExtendedPrice) AS SumInvoice
FROM WideWorldImporters.Sales.Invoices AS Invoices
JOIN WideWorldImporters.Sales.InvoiceLines AS InvoiceLines ON InvoiceLines.InvoiceID = Invoices.InvoiceID
GROUP BY MONTH(Invoices.InvoiceDate), YEAR(Invoices.InvoiceDate)
HAVING  SUM(InvoiceLines.ExtendedPrice) > 10000
ORDER BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate)

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT YEAR(Invoices.InvoiceDate) AS YearInvoice, MONTH(Invoices.InvoiceDate) AS MonthInvoice, StockItems.StockItemName, SUM(InvoiceLines.ExtendedPrice) AS SumInvoice, MIN(Invoices.InvoiceDate) AS MinInvoiceDate, SUM(InvoiceLines.Quantity) AS SumQ
FROM WideWorldImporters.Sales.Invoices AS Invoices
JOIN WideWorldImporters.Sales.InvoiceLines AS InvoiceLines ON InvoiceLines.InvoiceID = Invoices.InvoiceID
JOIN WideWorldImporters.Warehouse.StockItems AS StockItems ON StockItems.StockItemID = InvoiceLines.StockItemID
GROUP BY MONTH(Invoices.InvoiceDate), YEAR(Invoices.InvoiceDate), StockItems.StockItemName
HAVING  SUM(InvoiceLines.Quantity) < 50
ORDER BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate), SUM(InvoiceLines.Quantity)

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
